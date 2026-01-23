import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:easy_localization/easy_localization.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: fixPadding * 3),
        Divider(color: Colors.grey.shade300),
        SizedBox(height: fixPadding),
        Text(
          'footer.rights'.tr(),
          style: blackSmallTextStyle.copyWith(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'footer.website'.tr(),
          style: blackSmallTextStyle.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
