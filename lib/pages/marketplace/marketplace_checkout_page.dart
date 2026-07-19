import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_order_details_page.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// One delivery option Odoo (or the synthetic pickup entry) actually offers,
/// as returned by getMarketplaceDeliveryMethods (a thin relay to Commerce's
/// own delivery.carrier read, PLUS a synthesized pickup entry — see
/// doctor_functions/functions/commerce/marketplaceCheckout.js's own
/// DELIVERY_METHOD_LABELS/getMarketplaceDeliveryMethods). `fee` is
/// DISPLAY-ONLY here too: the authoritative fee is whatever Odoo computes
/// again at order-confirm time (placeMarketplaceOrderForHealthcare re-reads
/// the carrier's own fixed_price live, never trusting this cached copy).
/// Labels are fixed, reviewed EN/AR/KU strings keyed by [deliveryType] —
/// never derived from inspecting Odoo's raw English carrier name.
class _DeliveryMethod {
  const _DeliveryMethod({
    required this.carrierEngineId,
    required this.deliveryType,
    required this.nameEn,
    required this.nameAr,
    required this.nameKu,
    required this.fee,
    required this.freeOverThreshold,
    this.estimatedMinutesMin,
    this.estimatedMinutesMax,
    this.noteEn,
    this.noteAr,
    this.noteKu,
  });

  /// Null for pickup (no Odoo delivery.carrier — the Phase-1
  /// no-carrier-selected checkout path).
  final String? carrierEngineId;
  final String deliveryType; // 'pickup' | 'delivery'
  final String nameEn;
  final String nameAr;
  final String nameKu;
  final double fee;

  /// Odoo's delivery.carrier free_over/amount, null when no free-above-
  /// threshold rule is configured. Same display-only estimate rule as
  /// [fee] — the authoritative amount is always recomputed server-side.
  final double? freeOverThreshold;

  /// Store-owned display fields (organizations/{orgId}.storeSettings.
  /// delivery) — never price-affecting, always null for pickup.
  final int? estimatedMinutesMin;
  final int? estimatedMinutesMax;
  final String? noteEn;
  final String? noteAr;
  final String? noteKu;

  bool get isPickup => carrierEngineId == null;

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'ku') return nameKu;
    return nameEn;
  }

  String? localizedNote(String lang) {
    final note = lang == 'ar' ? noteAr : (lang == 'ku' ? noteKu : noteEn);
    return (note == null || note.trim().isEmpty) ? null : note;
  }

  factory _DeliveryMethod.fromMap(Map<String, dynamic> m) => _DeliveryMethod(
        carrierEngineId: m['carrierEngineId']?.toString(),
        deliveryType: m['deliveryType']?.toString() ?? 'delivery',
        nameEn: m['name_en']?.toString() ?? '',
        nameAr: m['name_ar']?.toString() ?? '',
        nameKu: m['name_ku']?.toString() ?? '',
        fee: (m['fee'] is num) ? (m['fee'] as num).toDouble() : 0,
        freeOverThreshold: (m['freeOverThreshold'] is num)
            ? (m['freeOverThreshold'] as num).toDouble()
            : null,
        estimatedMinutesMin: (m['estimatedDeliveryMinutesMin'] is num)
            ? (m['estimatedDeliveryMinutesMin'] as num).toInt()
            : null,
        estimatedMinutesMax: (m['estimatedDeliveryMinutesMax'] is num)
            ? (m['estimatedDeliveryMinutesMax'] as num).toInt()
            : null,
        noteEn: m['note_en']?.toString(),
        noteAr: m['note_ar']?.toString(),
        noteKu: m['note_ku']?.toString(),
      );
}

/// Mirrors Odoo's free-above-threshold rule (createPatientOrder,
/// odooDriver.ts) for the pre-submit display estimate only — the
/// authoritative amount always comes from the confirmed order.
double _effectiveFee(_DeliveryMethod m, double subtotal) {
  if (m.isPickup) return 0;
  final threshold = m.freeOverThreshold;
  if (threshold != null && subtotal >= threshold) return 0;
  return m.fee;
}

String _formatAmount(double amount, String? currency) {
  final formatted =
      amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  return currency == null ? formatted : '$formatted $currency'.trim();
}

String _deliveryFeeSubtitle(
    _DeliveryMethod m, double subtotal, String? currency) {
  final effective = _effectiveFee(m, subtotal);
  if (effective == 0) return 'marketplace_checkout_free'.tr();
  final base = _formatAmount(m.fee, currency);
  final threshold = m.freeOverThreshold;
  if (threshold == null) return base;
  final hint = 'marketplace_checkout_free_over_threshold'.tr(namedArgs: {
    'amount': _formatAmount(threshold, currency),
  });
  return '$base · $hint';
}

/// Minutes -> hours, display only (Option B) — the underlying
/// estimatedMinutesMin/Max values (and everything upstream: Firestore,
/// Commerce, the doctor_functions relay) stay in minutes; this is the one
/// place that formats them for a patient to read. Trims to a whole number
/// when exact (typical case, since the provider now only ever inputs whole
/// or half hours), one decimal place otherwise.
String _formatHours(int minutes) {
  final hours = minutes / 60.0;
  return hours == hours.roundToDouble()
      ? hours.toStringAsFixed(0)
      : hours.toStringAsFixed(1);
}

/// Store-owned display estimate (organizations/{orgId}.storeSettings.
/// delivery) — never affects pricing, purely informational. Null when the
/// pharmacy hasn't configured an estimate.
String? _deliveryEstimateText(_DeliveryMethod m) {
  final min = m.estimatedMinutesMin;
  final max = m.estimatedMinutesMax;
  if (min == null && max == null) return null;
  if (min != null && max != null && min != max) {
    return 'marketplace_checkout_delivery_estimate_range'.tr(namedArgs: {
      'min': _formatHours(min),
      'max': _formatHours(max),
    });
  }
  final minutes = min ?? max;
  return 'marketplace_checkout_delivery_estimate_single'
      .tr(namedArgs: {'hours': _formatHours(minutes!)});
}

/// Combines the fee line with the store's own display-only estimate/note —
/// pickup only ever shows the pickup-location row built separately below,
/// never this.
String? _deliveryTileSubtitle(
    _DeliveryMethod m, double subtotal, String? currency, String lang) {
  if (m.isPickup) return null;
  final lines = <String>[
    _deliveryFeeSubtitle(m, subtotal, currency),
    if (_deliveryEstimateText(m) case final estimate?) estimate,
    if (m.localizedNote(lang) case final note?) note,
  ];
  return lines.join('\n');
}

/// Synthesized locally — Odoo has no native pickup marker, and this is also
/// the degradation target when the delivery-methods read fails or the cart
/// has no orgId yet.
const _pickupOnlyFallback = <_DeliveryMethod>[
  _DeliveryMethod(
    carrierEngineId: null,
    deliveryType: 'pickup',
    nameEn: 'Store Pickup',
    nameAr: 'الاستلام من المتجر',
    nameKu: 'وەرگرتن لە فرۆشگا',
    fee: 0,
    freeOverThreshold: null,
  ),
];

/// Fetches the pickup + this store's own dedicated Odoo delivery.carrier
/// (Option B — one carrier per pharmacy; never a global/shared fallback)
/// once per checkout visit, scoped to the cart's own orgId. A failure here
/// (e.g. the relay isn't reachable) degrades to a pickup-only default
/// rather than blocking checkout entirely.
final _deliveryMethodsProvider = FutureProvider.autoDispose
    .family<List<_DeliveryMethod>, String>((ref, orgId) async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('getMarketplaceDeliveryMethods');
    final result = await callable.call<Map<String, dynamic>>({'orgId': orgId});
    final raw = result.data['methods'];
    if (raw is! List) return const [];
    return raw
        .map(
            (e) => _DeliveryMethod.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (_) {
    // Pickup-only degradation — see provider header comment.
    return _pickupOnlyFallback;
  }
});

/// The authenticated patient's real profile, resolved server-side
/// (getMarketplaceCheckoutProfile — doctor_functions/functions/commerce/
/// marketplaceCheckout.js) — never a client-side guess (Firebase Auth
/// displayName can be empty/stale). Used ONLY to prefill the form; the
/// patient may still edit every field before submitting, and the identity
/// actually bound to the Odoo customer record is re-resolved server-side
/// again at order-placement time regardless of what this page shows.
class _CheckoutProfile {
  const _CheckoutProfile({
    required this.name,
    required this.phone,
    required this.homeAddress,
  });

  final String name;
  final String phone;
  final Map<String, String>? homeAddress;

  factory _CheckoutProfile.fromMap(Map<String, dynamic> m) {
    final addr = m['homeAddress'];
    return _CheckoutProfile(
      name: m['name']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      homeAddress: addr is Map
          ? {
              'province': addr['province']?.toString() ?? '',
              'city': addr['city']?.toString() ?? '',
              'full': addr['full']?.toString() ?? '',
              'note': addr['note']?.toString() ?? '',
            }
          : null,
    );
  }
}

final _checkoutProfileProvider =
    FutureProvider.autoDispose<_CheckoutProfile>((ref) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('getMarketplaceCheckoutProfile');
  final result = await callable.call<Map<String, dynamic>>();
  return _CheckoutProfile.fromMap(result.data);
});

/// Checkout (Milestone 6). Reached only after ensureMarketplaceLogin has
/// already confirmed the caller is signed in (the Cart page's own gate) —
/// this page itself does not re-check auth, matching every other
/// already-gated page in this app.
class MarketplaceCheckoutPage extends ConsumerStatefulWidget {
  const MarketplaceCheckoutPage({super.key});

  @override
  ConsumerState<MarketplaceCheckoutPage> createState() =>
      _MarketplaceCheckoutPageState();
}

class _MarketplaceCheckoutPageState
    extends ConsumerState<MarketplaceCheckoutPage> {
  final _nameController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IQ');
  String? _selectedCarrierEngineId; // null == pickup
  bool _placing = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Prefill is a one-time default from the patient's real profile — once
  // applied, further profile refetches (e.g. autoDispose re-runs) must
  // never clobber an in-progress edit the patient has already made.
  void _applyPrefill(_CheckoutProfile profile) {
    if (_prefilled) return;
    _prefilled = true;
    if (_nameController.text.isEmpty) _nameController.text = profile.name;
    if (profile.phone.isNotEmpty) {
      _phoneNumber = PhoneNumber(phoneNumber: profile.phone, isoCode: 'IQ');
    }
    final addr = profile.homeAddress;
    if (addr != null) {
      _provinceController.text = addr['province'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _addressController.text = addr['full'] ?? '';
      _noteController.text = addr['note'] ?? '';
    }
  }

  Future<void> _placeOrder(Cart cart, _DeliveryMethod? selected) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _placing = true);

    final isDelivery = selected != null && !selected.isPickup;

    try {
      // A fresh, random unique key per checkout attempt — reused verbatim
      // on any client-side retry within this same screen instance so a
      // double-tap or network retry can never create two orders (the
      // idempotency contract placeMarketplaceOrder/placeMarketplaceOrderForHealthcare
      // already enforce server-side).
      final idempotencyKey =
          FirebaseFirestore.instance.collection('_').doc().id;

      final callable =
          FirebaseFunctions.instance.httpsCallable('placeMarketplaceOrder');
      final result =
          await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'orgId': cart.orgId,
        'idempotencyKey': idempotencyKey,
        // Milestone 5 (Patient Product Experience) — variantEngineId is
        // included only when the line actually has one (a multi-variant
        // product the patient resolved a specific choice for); a
        // single-variant line omits it entirely, letting the backend's own
        // resolveVariantDecision safely auto-select the one sellable
        // variant, exactly matching CartItem.variantEngineId's own
        // null-means-unambiguous contract.
        'lines': cart.items
            .map((i) => {
                  'productEngineId': i.productEngineId,
                  if (i.variantEngineId != null)
                    'variantEngineId': i.variantEngineId,
                  'quantity': i.quantity,
                })
            .toList(),
        'deliveryCarrierEngineId': selected?.carrierEngineId,
        'deliveryAddress': isDelivery
            ? {
                'name': _nameController.text.trim(),
                'phone': _phoneNumber.phoneNumber,
                'province': _provinceController.text.trim(),
                'city': _cityController.text.trim(),
                'full': _addressController.text.trim(),
                'note': _noteController.text.trim(),
              }
            : null,
        'locale': context.locale.languageCode,
        'storeNameEn': cart.storeNameEn,
        'storeNameAr': cart.storeNameAr,
      });

      final orderId = (result.data['orderId'] ?? idempotencyKey).toString();
      final order =
          Map<String, dynamic>.from(result.data['order'] as Map? ?? {});
      await ref.read(marketplaceCartProvider.notifier).clear();

      if (!mounted) return;
      // Land directly on the new order's details page — the confirmation
      // flow's real entry point, not a temporary SnackBar the patient could
      // miss (a lightweight toast is shown alongside, not instead of, this
      // navigation).
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarketplaceOrderDetailsPage(orderId: orderId),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('marketplace_order_placed'.tr(namedArgs: {
            'name': (order['name'] ?? '').toString(),
          })),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      String message;
      if (e.code == 'invalid-argument' &&
          (e.details is Map) &&
          (e.details as Map)['code'] == 'delivery_address_required') {
        message = 'marketplace_checkout_delivery_address_required_error'.tr();
      } else if (e.code == 'failed-precondition' &&
          (e.message ?? '').toLowerCase().contains('profile name')) {
        message = 'marketplace_checkout_profile_incomplete_error'.tr();
      } else if (e.code == 'failed-precondition') {
        message = e.message ?? 'marketplace_checkout_generic_error'.tr();
      } else {
        message = 'marketplace_checkout_generic_error'.tr();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('marketplace_checkout_generic_error'.tr())),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(marketplaceCartProvider);
    final orgId = cart.orgId;
    final deliveryMethodsAsync = orgId == null
        ? const AsyncValue<List<_DeliveryMethod>>.data(_pickupOnlyFallback)
        : ref.watch(_deliveryMethodsProvider(orgId));
    final profileAsync = ref.watch(_checkoutProfileProvider);
    profileAsync.whenData(_applyPrefill);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('marketplace_checkout_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = _buildForm(cart, deliveryMethodsAsync);
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }

  Widget _buildForm(
    Cart cart,
    AsyncValue<List<_DeliveryMethod>> deliveryMethodsAsync,
  ) {
    final lang = context.locale.languageCode;
    final methods = deliveryMethodsAsync.value ?? const <_DeliveryMethod>[];
    final selected = methods
        .where((m) =>
            m.carrierEngineId == _selectedCarrierEngineId ||
            (m.carrierEngineId == null && _selectedCarrierEngineId == null))
        .toList();
    final selectedMethod = selected.isNotEmpty ? selected.first : null;
    final isDelivery = selectedMethod != null && !selectedMethod.isPickup;
    final storeName = (lang == 'ar' ? cart.storeNameAr : cart.storeNameEn) ??
        cart.storeNameEn ??
        cart.storeNameAr ??
        '';

    final currency =
        cart.items.isNotEmpty ? cart.items.first.currencyName : null;
    final subtotal = cart.estimatedSubtotal;
    // Mirrors the free-above-threshold rule Odoo applies server-side
    // (createPatientOrder, odooDriver.ts) purely for this pre-submit
    // estimate — the real amount always comes from the confirmed order.
    final deliveryFee =
        isDelivery ? _effectiveFee(selectedMethod, subtotal) : 0.0;
    final total = subtotal + deliveryFee;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('marketplace_checkout_contact_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'marketplace_checkout_name_label'.tr(),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'marketplace_checkout_name_required'.tr()
                : null,
          ),
          const SizedBox(height: 12),
          InternationalPhoneNumberInput(
            onInputChanged: (phone) => _phoneNumber = phone,
            initialValue: _phoneNumber,
            selectorConfig: const SelectorConfig(
                selectorType: PhoneInputSelectorType.DIALOG),
            inputDecoration: InputDecoration(
              labelText: 'marketplace_checkout_phone_label'.tr(),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text('marketplace_checkout_delivery_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          deliveryMethodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (loadedMethods) => Column(
              children: loadedMethods
                  .map((m) => _DeliveryOptionTile(
                        label: m.localizedName(lang),
                        subtitle:
                            _deliveryTileSubtitle(m, subtotal, currency, lang),
                        selected: _selectedCarrierEngineId == m.carrierEngineId,
                        onTap: () => setState(
                            () => _selectedCarrierEngineId = m.carrierEngineId),
                      ))
                  .toList(),
            ),
          ),
          if (!isDelivery && storeName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront, size: 15, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'marketplace_checkout_pickup_location'
                        .tr(namedArgs: {'store': storeName}),
                    style:
                        const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
          if (isDelivery) ...[
            const SizedBox(height: 20),
            Text('marketplace_checkout_delivery_address_section'.tr(),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _provinceController,
              decoration: InputDecoration(
                labelText: 'marketplace_checkout_province_label'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => (isDelivery && (v == null || v.trim().isEmpty))
                  ? 'marketplace_checkout_address_required'.tr()
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'marketplace_checkout_city_label'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => (isDelivery && (v == null || v.trim().isEmpty))
                  ? 'marketplace_checkout_address_required'.tr()
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'marketplace_checkout_address_label'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => (isDelivery && (v == null || v.trim().isEmpty))
                  ? 'marketplace_checkout_address_required'.tr()
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'marketplace_checkout_address_note_label'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('marketplace_checkout_order_summary_section'.tr(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'marketplace_checkout_subtotal_label'.tr(),
                  value:
                      '${subtotal.toStringAsFixed(subtotal.truncateToDouble() == subtotal ? 0 : 2)} ${currency ?? ''}'
                          .trim(),
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'marketplace_checkout_delivery_fee_label'.tr(),
                  value: !isDelivery
                      ? 'marketplace_checkout_free'.tr()
                      : (deliveryFee == 0
                          ? 'marketplace_checkout_free'.tr()
                          : '${deliveryFee.toStringAsFixed(deliveryFee.truncateToDouble() == deliveryFee ? 0 : 2)} ${currency ?? ''}'
                              .trim()),
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'marketplace_checkout_total_label'.tr(),
                  value:
                      '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} ${currency ?? ''}'
                          .trim(),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientAppColors.brandTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_placing || cart.isEmpty)
                  ? null
                  : () => _placeOrder(cart, selectedMethod),
              child: _placing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('marketplace_place_order'.tr(),
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 14.5 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: bold ? Colors.black87 : Colors.black54,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  const _DeliveryOptionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? PatientAppColors.brandTeal : Colors.black12,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<bool>(
        value: true,
        groupValue: selected ? true : null,
        onChanged: (_) => onTap(),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        activeColor: PatientAppColors.brandTeal,
      ),
    );
  }
}
