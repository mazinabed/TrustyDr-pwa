import 'package:trustydr/constant/constant.dart' hide blackColor;
import 'package:trustydr/pages/contact_us_page.dart';
import 'package:trustydr/pages/faq_page.dart';
import 'package:trustydr/pages/help_support.dart';
import 'package:trustydr/pages/legal_disclaimer_page.dart';
import 'package:trustydr/pages/privacy_policy_page.dart';
import 'package:trustydr/pages/screens.dart';
import 'package:trustydr/pages/terms_conditions_page.dart';
import 'package:trustydr/services/database_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _db = DatabaseService.instance;
  String userName = '';
  String? userPhoto;
  bool _isLoadingProfile = false;
  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = FirebaseAuth.instance.currentUser;

    // 🔒 Treat anonymous users as guests
    final isGuest = user == null || user.isAnonymous;

    if (!isGuest && !_hasLoadedOnce) {
      _loadProfile();
      _hasLoadedOnce = true;
    }
  }

  String _resolveLocalizedName(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;

    if (value is Map<String, dynamic>) {
      final lang = context.locale.languageCode;
      return value[lang] ?? value['en'] ?? value.values.first.toString();
    }

    return '';
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _isLoadingProfile = true);

    try {
      final cached = await _db.getCachedUser();
      if (cached != null && mounted) {
        setState(() {
          userName = _resolveLocalizedName(cached['name']);
          if (userName.isEmpty) {
            userName = user.displayName ?? tr('user');
          }

          final img = (cached['profileImage'] as String?)?.trim();
          userPhoto = (img != null && img.startsWith('http') && img.isNotEmpty)
              ? img
              : null;
        });
      }

      final fresh = await _db.fetchCurrentUserProfile();
      if (fresh != null && mounted) {
        setState(() {
          userName = _resolveLocalizedName(fresh['name']);
          if (userName.isEmpty) {
            userName = user.displayName ?? tr('user');
          }

          final img = (fresh['profileImage'] as String?)?.trim();
          userPhoto = (img != null && img.startsWith('http') && img.isNotEmpty)
              ? img
              : null;
        });
      }

      if ((user.displayName == null || user.displayName!.isEmpty) &&
          userName.isNotEmpty) {
        await user.updateDisplayName(userName);
        await user.reload();
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingProfile = false);
  }

  Future<void> _logout() async {
    await _db.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageTransition(
        type: PageTransitionType.fade,
        child: const LoginScreen(),
        duration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  void _guardedPush(Widget page) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginSheet();
    } else {
      final result = await Navigator.push(
        context,
        PageTransition(type: PageTransitionType.rightToLeft, child: page),
      );
      if (result == true) {
        await _loadProfile();
      }
    }
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: PatientAppColors.brandIndigo.withOpacity(0.12),
              child: Icon(Icons.lock_outline,
                  size: 28, color: PatientAppColors.brandIndigo),
            ),
            const SizedBox(height: 12),
            Text(tr('login_required'), style: blackHeadingTextStyle),
            const SizedBox(height: 8),
            Text(
              tr('login_required_feature'),
              textAlign: TextAlign.center,
              style: greySmallTextStyle,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientAppColors.brandIndigo,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const LoginScreen(),
                  ),
                );
              },
              child: Text(tr('go_to_login'), style: whiteColorButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar({double size = 64}) {
    final img = userPhoto;
    if (img == null || img.isEmpty || !img.startsWith('http')) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.asset(
            'assets/user/placeholder_user.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: FadeInImage(
          placeholder: const AssetImage('assets/user/placeholder_user.png'),
          image: ResizeImage(
            NetworkImage(img),
            width: (size * 2).toInt(), // ✅ cache hint (retina-safe)
          ),
          width: size,
          height: size,
          fit: BoxFit.cover,
          imageErrorBuilder: (_, __, ___) => Image.asset(
            'assets/user/placeholder_user.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return _buildGuestView();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: LayoutBuilder(
            builder: (context, constraints) {
              Widget content = SafeArea(
                child: RefreshIndicator(
                  color: PatientAppColors.brandIndigo,
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                          decoration: const BoxDecoration(
                            gradient: PatientAppColors.brandGradient,
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(36)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tr('my_profile'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _guardedPush(const EditProfile()),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.18),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: Text(
                                      tr('edit'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _avatar(size: 72),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isLoadingProfile
                                              ? tr('loading')
                                              : (userName.isEmpty
                                                  ? tr('user')
                                                  : userName),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          user.phoneNumber ??
                                              user.email ??
                                              tr('signed_in'),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -60),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _sectionCard(
                                  title: tr('my_account'),
                                  items: [
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.local_hospital,
                                      label: tr('my_doctors'),
                                      onTap: () =>
                                          _guardedPush(const MyDoctorsPage()),
                                    ),
                                    _ActionItem(
                                      color: PatientAppColors.brandTeal,
                                      icon: Icons.calendar_today,
                                      label: tr('my_appointments'),
                                      onTap: () => _guardedPush(
                                          const MyAppointmentsPage(
                                              showBack: true)),
                                    ),
                                    _ActionItem(
                                      color: Colors.purple,
                                      icon: Icons.thumb_up,
                                      label: tr('recommendations'),
                                      onTap: () => _guardedPush(
                                          const RecommendationsPage()),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _sectionCard(
                                  title: tr('about_app'),
                                  items: [
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.info_outline,
                                      label: tr('about_us'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const AboutUs(),
                                        ),
                                      ),
                                    ),
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.help_outline,
                                      label: tr('help_support'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const HelpSupportPage(),
                                        ),
                                      ),
                                    ),
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.quiz_outlined,
                                      label: tr('faq.title'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const FAQPage(),
                                        ),
                                      ),
                                    ),
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.contact_mail_outlined,
                                      label: tr('contact.title'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const ContactUsPage(),
                                        ),
                                      ),
                                    ),
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.lock_outline,
                                      label: tr('privacy.title'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const PrivacyPolicyPage(),
                                        ),
                                      ),
                                    ),
                                    _ActionItem(
                                      color: PatientAppColors.brandIndigo,
                                      icon: Icons.description_outlined,
                                      label: tr('terms.title'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const TermsConditionsPage(),
                                        ),
                                      ),
                                    ),
                                    _ActionItem(
                                      color: Colors.redAccent,
                                      icon: Icons.gavel_outlined,
                                      label: tr('legal.title'),
                                      onTap: () => Navigator.push(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: const LegalDisclaimerPage(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _logoutCard(onLogout: _logout),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (constraints.maxWidth >= 768)
                content = WebScaffoldContainer(child: content);
              return content;
            },
          ),
        );
      },
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: PatientAppColors.brandGradient,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _avatar(size: 80),
                  const SizedBox(height: 12),
                  Text(
                    tr('not_logged_in'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('sign_in_message'),
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: PatientAppColors.brandIndigo,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      tr('login'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      {required String title, required List<_ActionItem> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: blackHeadingTextStyle),
          const SizedBox(height: 8),
          ...items.map((i) => _tile(i)),
        ],
      ),
    );
  }

  Widget _tile(_ActionItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(width: 0.25, color: item.color),
                color: item.color.withOpacity(0.12),
              ),
              child: Icon(item.icon, size: 22, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label, style: blackNormalBoldTextStyle),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: blackColor),
          ],
        ),
      ),
    );
  }

  Widget _logoutCard({required VoidCallback onLogout}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.exit_to_app),
        label: Text(
          tr('logout'),
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: PatientAppColors.brandIndigo,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionItem({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
