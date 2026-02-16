import 'package:flutter/material.dart';

class PublicDoctorProfilePage extends StatelessWidget {
  final String doctorId;

  const PublicDoctorProfilePage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: Center(
        child: Text(
          'Doctor ID:\n$doctorId',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
