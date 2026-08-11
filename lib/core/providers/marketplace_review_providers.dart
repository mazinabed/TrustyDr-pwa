// Product Ratings & Reviews, Phase 5 (2026-08-10) — Patient-side models/
// providers for the review read/write paths already built in Phases 1-3
// (doctor_functions/functions/commerce/marketplaceProductReview.js's
// submitProductReview/withdrawProductReview/getMyProductReview/
// getProductReviews). Same file-organization convention as
// marketplace_providers.dart (models + their providers colocated, never
// split into a separate model file), kept in its own sibling file since
// Reviews is a genuinely distinct concern from product browsing/checkout
// (same precedent as marketplace_cart_provider.dart's own split-out file).
//
// This file never reproduces Verified Purchase logic — every callable here
// is a thin relay to the existing Healthcare bridge; the backend remains
// the sole authority on eligibility, one-review-per-product enforcement,
// and rating validity. Errors are surfaced as-is (FirebaseFunctionsException)
// for the UI layer to map to a localized message — no `.tr()` calls in this
// file, matching marketplace_providers.dart's own established convention.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Map<String, dynamic> _asStringKeyedMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}

/// Odoo's own datetime wire format ("YYYY-MM-DD HH:MM:SS", UTC, no offset
/// marker) — never assume ISO8601 directly parses it. Returns null (never
/// throws) for a missing/malformed value so a review card degrades to no
/// date shown rather than crashing.
DateTime? parseOdooReviewDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final normalized =
        raw.contains('T') ? raw : '${raw.replaceFirst(' ', 'T')}Z';
    return DateTime.parse(normalized);
  } catch (_) {
    return null;
  }
}

/// One product review — mirrors trustydr-commerce's EngineProductReview
/// wire shape exactly (Phase 1/2). [reviewerDisplayName] is already the
/// privacy-conscious "First L." partial name (or "" when not applicable —
/// see that type's own doc comment for when it's blank vs populated),
/// never the reviewer's full name; this app must never attempt to derive
/// or show a fuller name than what the backend already sends.
class ProductReview {
  const ProductReview({
    required this.reviewEngineId,
    required this.reviewerDisplayName,
    required this.rating,
    required this.feedback,
    required this.createDate,
  });

  final String reviewEngineId;
  final String reviewerDisplayName;
  final int rating;
  final String? feedback;
  final DateTime? createDate;

  factory ProductReview.fromMap(Map<String, dynamic> m) {
    final rawFeedback = m['feedback'];
    return ProductReview(
      reviewEngineId: m['reviewEngineId']?.toString() ?? '',
      reviewerDisplayName: m['reviewerDisplayName']?.toString() ?? '',
      rating: (m['rating'] is num) ? (m['rating'] as num).round() : 0,
      feedback: (rawFeedback is String && rawFeedback.trim().isNotEmpty)
          ? rawFeedback
          : null,
      createDate: parseOdooReviewDate(m['createDate']?.toString()),
    );
  }
}

/// Matches the Commerce driver's own default page size expectation — kept
/// as a named constant here so the "Load More" flow and the initial fetch
/// can never drift apart on page size.
const int kProductReviewsPageSize = 10;

/// First page of a product's reviews, newest first — same public/
/// unauthenticated posture as [getProductReviews] itself (see that
/// function's own header: non-sensitive general content). Subsequent
/// pages are fetched directly via [fetchMoreProductReviews] and appended
/// to local widget state (see _ReviewsSection) — a FutureProvider.family
/// models "the first page for this product," not the full paginated list,
/// matching this app's existing precedent of keeping pagination as local
/// widget state rather than provider state (e.g. no provider owns cart
/// pagination either).
final productReviewsProvider =
    FutureProvider.autoDispose.family<List<ProductReview>, String>(
  (ref, engineId) async {
    if (engineId.isEmpty) return const [];
    final callable =
        FirebaseFunctions.instance.httpsCallable('getProductReviews');
    final result = await callable.call<Map<String, dynamic>>({
      'engineId': engineId,
      'limit': kProductReviewsPageSize,
      'offset': 0,
    });
    final data = _asStringKeyedMap(result.data);
    final rawReviews = data['reviews'];
    if (rawReviews is! List) return const [];
    return rawReviews
        .map((e) => ProductReview.fromMap(_asStringKeyedMap(e)))
        .toList();
  },
);

/// "Load More" — a direct call, not a provider (see productReviewsProvider's
/// own doc comment for why pagination stays local widget state here).
Future<List<ProductReview>> fetchMoreProductReviews({
  required String engineId,
  required int offset,
}) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('getProductReviews');
  final result = await callable.call<Map<String, dynamic>>({
    'engineId': engineId,
    'limit': kProductReviewsPageSize,
    'offset': offset,
  });
  final data = _asStringKeyedMap(result.data);
  final rawReviews = data['reviews'];
  if (rawReviews is! List) return const [];
  return rawReviews
      .map((e) => ProductReview.fromMap(_asStringKeyedMap(e)))
      .toList();
}

/// This patient's own review status for a product — used to decide between
/// the three Write/Edit/no-action states (live-test follow-up, 2026-08-11:
/// every product's write action was appearing regardless of purchase
/// history). [eligibleToReview] comes straight from the backend's
/// getMyProductReviewForHealthcare (Phase 1's existing, authoritative
/// hasVerifiedPurchase check, reused — never recalculated here): this app
/// must never decide eligibility itself from order history.
class MyReviewStatus {
  const MyReviewStatus({required this.review, required this.eligibleToReview});

  final ProductReview? review;
  final bool eligibleToReview;

  static const none = MyReviewStatus(review: null, eligibleToReview: false);
}

/// This patient's own review for a product (or null) plus whether they are
/// eligible to write a new one. Guarded against a guest session the same
/// way every other auth-gated read in this app guards a Firestore stream
/// (firestore-safety.md §5's Stream.empty() convention, applied here to a
/// callable instead): a guest has no review and is never eligible by
/// definition, and calling the backend would only produce an
/// unauthenticated error for no reason.
final myProductReviewProvider =
    FutureProvider.autoDispose.family<MyReviewStatus, String>(
  (ref, engineId) async {
    if (engineId.isEmpty) return MyReviewStatus.none;
    if (FirebaseAuth.instance.currentUser == null) return MyReviewStatus.none;
    final callable =
        FirebaseFunctions.instance.httpsCallable('getMyProductReview');
    final result =
        await callable.call<Map<String, dynamic>>({'engineId': engineId});
    final data = _asStringKeyedMap(result.data);
    final rawReview = data['review'];
    final review = rawReview == null
        ? null
        : ProductReview.fromMap(_asStringKeyedMap(rawReview));
    return MyReviewStatus(
      review: review,
      eligibleToReview: data['eligibleToReview'] == true,
    );
  },
);

/// Create-or-update. Verified Purchase / rating-value validity are
/// re-checked authoritatively on the backend on every call (Phase 1's
/// upsertProductReview) — this function never guesses eligibility, it only
/// surfaces whatever FirebaseFunctionsException the backend throws for the
/// caller (the write sheet UI) to map to a localized message.
Future<void> submitProductReview({
  required String engineId,
  required int rating,
  String? feedback,
  required String locale,
}) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('submitProductReview');
  await callable.call<Map<String, dynamic>>({
    'engineId': engineId,
    'rating': rating,
    if (feedback != null && feedback.trim().isNotEmpty)
      'feedback': feedback.trim(),
    'locale': locale,
  });
}

/// Withdraw — idempotent on the backend (Phase 1's withdrawProductReview
/// returns {withdrawn:false} rather than throwing for "nothing to
/// withdraw"), so this never needs its own not-found handling here.
Future<void> withdrawProductReview({
  required String engineId,
  required String locale,
}) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('withdrawProductReview');
  await callable
      .call<Map<String, dynamic>>({'engineId': engineId, 'locale': locale});
}
