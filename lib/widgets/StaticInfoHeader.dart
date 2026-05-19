// static_info_header.dart
import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

class StaticInfoHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const StaticInfoHeader({
    super.key,
    required this.title,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 48),
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
    );
  }
}
