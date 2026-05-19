// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';

// class GoogleClinicDetailsPage extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const GoogleClinicDetailsPage({
//     super.key,
//     required this.data,
//   });

//   Widget _benefitItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           const Icon(Icons.check_circle, color: Colors.teal, size: 20),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _displayAddress(Map<String, dynamic> data) {
//     final rawAddress = (data['address'] ?? '').toString().trim();
//     final city = (data['city'] ?? data['city_en'] ?? '').toString().trim();
//     final province = (data['province'] ?? '').toString().trim();

//     // 1️⃣ Clean, normal address → show it
//     if (rawAddress.isNotEmpty && !rawAddress.contains('+')) {
//       return rawAddress;
//     }

//     // 2️⃣ Fallback: City + Province
//     if (city.isNotEmpty && province.isNotEmpty) {
//       return '$city, $province';
//     }

//     if (city.isNotEmpty) {
//       return city;
//     }

//     // 3️⃣ Last resort
//     return tr('address_not_available');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(tr('clinic_details')),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // -------------------------
//             // Clinic Name
//             // -------------------------
//             Text(
//               data['name'] ?? '',
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 6),
//             if ((data['specialty'] ?? '').toString().isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 6),
//                 child: Text(
//                   '${tr('listed_specialty')}: ${data['specialty']}',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.teal,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),

//             // -------------------------
//             // Address
//             // -------------------------
//             Text(
//               _displayAddress(data),
//               style: const TextStyle(color: Colors.black54),
//             ),

//             const SizedBox(height: 12),

//             // -------------------------
//             // Status Chips
//             // -------------------------
//             Row(
//               children: [
//                 Chip(
//                   label: Text(tr('from_google')),
//                   backgroundColor: Colors.orange.shade100,
//                 ),
//                 const SizedBox(width: 8),
//                 Chip(
//                   label: Text(tr('info_only')),
//                   backgroundColor: Colors.grey.shade200,
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),
//             const Divider(),

//             // -------------------------
//             // Claim Clinic Section
//             // -------------------------
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Title
//                     Text(
//                       tr('are_you_owner'),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(height: 6),

//                     // Subtitle
//                     Text(
//                       tr('claim_description'),
//                       style: const TextStyle(color: Colors.black54),
//                     ),

//                     const SizedBox(height: 16),

//                     // Benefits
//                     _benefitItem(tr('benefit_verified')),
//                     _benefitItem(tr('benefit_bookings')),
//                     _benefitItem(tr('benefit_manage_profile')),
//                     _benefitItem(tr('benefit_trust')),

//                     const SizedBox(height: 20),

//                     // CTA Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           // TODO: open doctor portal in browser
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.teal,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           tr('claim_or_register'),
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     Center(
//                       child: Text(
//                         tr('claim_disclaimer'),
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.black45,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleClinicDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const GoogleClinicDetailsPage({
    super.key,
    required this.data,
  });

  Widget _benefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _displayAddress(Map<String, dynamic> data) {
    final rawAddress = (data['address'] ?? '').toString().trim();
    final city = (data['city_en'] ?? '').toString().trim();
    final province = (data['province_en'] ?? '').toString().trim();

    if (rawAddress.isNotEmpty && !rawAddress.contains('+')) {
      return rawAddress;
    }

    if (city.isNotEmpty && province.isNotEmpty) {
      return '$city, $province';
    }

    if (city.isNotEmpty) {
      return city;
    }

    return tr('address_not_available');
  }

  Future<void> _callClinic(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final phone = (data['phone'] ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: PatientAppColors.brandIndigo),
        title: Text(
          tr('clinic_details'),
          style: TextStyle(
            color: PatientAppColors.brandIndigo,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // Clinic Name
            // -------------------------
            Text(
              data['name'] ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            if ((data['specialty'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${tr('listed_specialty')}: ${data['specialty']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // -------------------------
            // Address
            // -------------------------
            const SizedBox(height: 6),
            Text(
              _displayAddress(data),
              style: const TextStyle(color: Colors.black54),
            ),

            // -------------------------
            // Phone (ALWAYS SHOWN)
            // -------------------------
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.phone, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: phone.isNotEmpty
                      ? Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          tr('phone_not_available'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),
              ],
            ),

            if (phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _callClinic(phone),
                  icon: const Icon(Icons.call),
                  label: Text(tr('call_clinic')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // -------------------------
            // Status Chips
            // -------------------------
            Row(
              children: [
                Chip(
                  label: Text(tr('from_google')),
                  backgroundColor: Colors.orange.shade100,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(tr('info_only')),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),

            // -------------------------
            // Claim Clinic Section
            // -------------------------
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('are_you_owner'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('claim_description'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    _benefitItem(tr('benefit_verified')),
                    _benefitItem(tr('benefit_bookings')),
                    _benefitItem(tr('benefit_manage_profile')),
                    _benefitItem(tr('benefit_trust')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: open doctor portal
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tr('claim_or_register'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        tr('claim_disclaimer'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
