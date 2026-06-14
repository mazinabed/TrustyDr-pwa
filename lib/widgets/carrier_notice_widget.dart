import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CarrierNoticeWidget extends StatelessWidget {
  const CarrierNoticeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode != 'en';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFCC02)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFF9A825)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'carrier_notice_asiacell'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5D4037),
                height: 1.45,
              ),
              textDirection:
                  isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}
