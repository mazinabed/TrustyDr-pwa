import 'package:flutter/material.dart';
import 'package:trustydr/pages/doctor/doctor_profile_v2.dart';

class PublicDoctorProfilePage extends StatelessWidget {
  final String doctorId;

  const PublicDoctorProfilePage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return DoctorProfileV2(doctorId: doctorId);
  }
}
