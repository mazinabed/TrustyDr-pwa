import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widgets/app_footer.dart';

//This widget will:

// Render the gradient header

// Render a list of cards

// Optionally show the footer

// Keep all pages consistent

class StaticInfoPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showFooter;

  const StaticInfoPage({
    super.key,
    required this.title,
    required this.children,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        children: [
          // 🔵 Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + fixPadding * 2,
              bottom: fixPadding * 3,
            ),
            decoration: const BoxDecoration(
              gradient: PatientAppColors.infoGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ⚪ Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(fixPadding * 2),
              children: [
                ...children,
                if (showFooter) const AppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
