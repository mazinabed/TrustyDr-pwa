import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:trustydr/data/services/auth_service.dart';
import 'package:trustydr/pages/profile/ChangePhoneNumberScreen.dart';
import 'package:trustydr/pages/profile/link_phone_screen.dart';
import 'package:trustydr/widgets/StaticInfoHeader.dart';

class AccountConnectionsScreen extends ConsumerStatefulWidget {
  const AccountConnectionsScreen({super.key});

  @override
  ConsumerState<AccountConnectionsScreen> createState() =>
      _AccountConnectionsScreenState();
}

class _AccountConnectionsScreenState
    extends ConsumerState<AccountConnectionsScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;

  UserInfo? _provider(String providerId) {
    return _user?.providerData
        .where((p) => p.providerId == providerId)
        .firstOrNull;
  }

  bool get _hasPhone => _provider('phone') != null;
  bool get _hasGoogle => _provider('google.com') != null;

  bool _googleLoading = false;

  Future<void> _connectGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authServiceProvider).linkGoogleProvider();
      await _user?.reload();
      if (mounted) {
        setState(() => _googleLoading = false);
        Fluttertoast.showToast(msg: 'account_connections.success'.tr());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _googleLoading = false);
        final msg = _localizedError(e.code);
        Fluttertoast.showToast(msg: msg);
      }
    } catch (_) {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _addPhone() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LinkPhoneScreen()),
    );
    if (result == true) {
      await _user?.reload();
      if (mounted) setState(() {});
    }
  }

  Future<void> _changePhone() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangePhoneNumberScreen()),
    );
    await _user?.reload();
    if (mounted) setState(() {});
  }

  String _localizedError(String code) {
    switch (code) {
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'account_connections.error_in_use'.tr();
      case 'provider-already-linked':
        return 'account_connections.error_linked'.tr();
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StaticInfoHeader(
            title: 'account_connections.title'.tr(),
            showBack: true,
          ),
          const SizedBox(height: 24),
          Text(
            'account_connections.login_methods'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _ProviderTile(
            icon: Icons.phone_outlined,
            label: 'account_connections.phone'.tr(),
            subtitle: _hasPhone
                ? (_provider('phone')?.phoneNumber ??
                    'account_connections.connected'.tr())
                : 'account_connections.not_connected'.tr(),
            isConnected: _hasPhone,
            actionLabel: _hasPhone
                ? 'auth.changePhone'.tr()
                : 'account_connections.add_phone'.tr(),
            onAction: _hasPhone ? _changePhone : _addPhone,
          ),
          const SizedBox(height: 12),
          _ProviderTile(
            icon: Icons.g_mobiledata,
            label: 'account_connections.google'.tr(),
            subtitle: _hasGoogle
                ? (_provider('google.com')?.email ??
                    'account_connections.connected'.tr())
                : 'account_connections.not_connected'.tr(),
            isConnected: _hasGoogle,
            actionLabel:
                _hasGoogle ? null : 'account_connections.connect_google'.tr(),
            onAction: _hasGoogle ? null : _connectGoogle,
            actionLoading: _googleLoading,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'account_connections.note'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isConnected;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;

  const _ProviderTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isConnected,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: isConnected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            isConnected ? Colors.green.shade700 : Colors.grey,
                      ),
                ),
              ],
            ),
          ),
          if (actionLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            )
          else if (isConnected)
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
        ],
      ),
    );
  }
}
