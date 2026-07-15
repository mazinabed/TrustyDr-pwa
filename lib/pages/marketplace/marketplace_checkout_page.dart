import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_orders_page.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// One delivery option Odoo actually offers, as returned by
/// getMarketplaceDeliveryMethods (a thin relay to Commerce's own
/// delivery.carrier read — see doctor_functions/functions/commerce/
/// marketplaceCheckout.js). fixedPrice is DISPLAY-ONLY here too: the
/// authoritative fee is whatever Odoo computes again at order-confirm time
/// (placeMarketplaceOrderForHealthcare re-reads the carrier's own
/// fixed_price live, never trusting this cached copy).
class _DeliveryMethod {
  const _DeliveryMethod({
    required this.engineId,
    required this.name,
    required this.fixedPrice,
  });

  final String engineId;
  final String name;
  final double? fixedPrice;

  factory _DeliveryMethod.fromMap(Map<String, dynamic> m) => _DeliveryMethod(
        engineId: m['engineId']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        fixedPrice: (m['fixedPrice'] is num)
            ? (m['fixedPrice'] as num).toDouble()
            : null,
      );
}

/// Fetches Odoo's real delivery.carrier list once per checkout visit. A
/// failure here (e.g. the relay isn't reachable) degrades to "pickup only"
/// rather than blocking checkout entirely — delivery selection is an
/// enhancement to the order, not a precondition for placing one.
final _deliveryMethodsProvider =
    FutureProvider.autoDispose<List<_DeliveryMethod>>((ref) async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('getMarketplaceDeliveryMethods');
    final result = await callable.call<Map<String, dynamic>>();
    final raw = result.data['methods'];
    if (raw is! List) return const [];
    return raw
        .map(
            (e) => _DeliveryMethod.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.engineId.isNotEmpty)
        .toList();
  } catch (_) {
    // Pickup-only degradation — see class header comment.
    return const [];
  }
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
  final _formKey = GlobalKey<FormState>();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IQ');
  String? _selectedDeliveryEngineId; // null == pickup
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(Cart cart) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _placing = true);

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
        'lines': cart.items
            .map((i) =>
                {'productEngineId': i.productEngineId, 'quantity': i.quantity})
            .toList(),
        'deliveryCarrierEngineId': _selectedDeliveryEngineId,
        'patientName': _nameController.text.trim(),
        'patientPhone': _phoneNumber.phoneNumber,
      });

      final order =
          Map<String, dynamic>.from(result.data['order'] as Map? ?? {});
      await ref.read(marketplaceCartProvider.notifier).clear();

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Row(
            children: [
              Expanded(
                child: Text(
                  'marketplace_order_placed'.tr(namedArgs: {
                    'name': (order['name'] ?? '').toString(),
                  }),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MarketplaceOrdersPage()),
                ),
                child: Text('marketplace_view_my_orders'.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final message = e.code == 'failed-precondition'
          ? (e.message ?? 'marketplace_checkout_generic_error'.tr())
          : 'marketplace_checkout_generic_error'.tr();
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
    final deliveryMethodsAsync = ref.watch(_deliveryMethodsProvider);

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
            error: (_, __) => _DeliveryOptionTile(
              label: 'marketplace_checkout_pickup_option'.tr(),
              subtitle: null,
              selected: true,
              onTap: () {},
            ),
            data: (methods) => Column(
              children: [
                _DeliveryOptionTile(
                  label: 'marketplace_checkout_pickup_option'.tr(),
                  subtitle: null,
                  selected: _selectedDeliveryEngineId == null,
                  onTap: () => setState(() => _selectedDeliveryEngineId = null),
                ),
                ...methods.map((m) => _DeliveryOptionTile(
                      label: m.name,
                      subtitle: m.fixedPrice?.toStringAsFixed(
                          m.fixedPrice!.truncateToDouble() == m.fixedPrice
                              ? 0
                              : 2),
                      selected: _selectedDeliveryEngineId == m.engineId,
                      onTap: () => setState(
                          () => _selectedDeliveryEngineId = m.engineId),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 28),
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
              onPressed:
                  (_placing || cart.isEmpty) ? null : () => _placeOrder(cart),
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
