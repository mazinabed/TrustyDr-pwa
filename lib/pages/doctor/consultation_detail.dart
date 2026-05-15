import 'package:firebase_auth/firebase_auth.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/data/services/appointment_builder.dart';
import 'package:trustydr/pages/screens.dart' hide blackColor;
import 'package:trustydr/services/database_service.dart';
import 'package:trustydr/pages/bottom_bar.dart';

class Patient {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isSelf;
  final int age;

  Patient({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isSelf = false,
    this.age = 0,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Patient(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      avatarUrl: data['image'],
      isSelf: data['isSelf'] ?? false,
      age: data['age'] ?? 0,
    );
  }
}

class ConsultationDetail extends StatefulWidget {
  final String doctorId;
  final String doctorName, doctorImage, doctorType, doctorExp;
  final String? date, time;
  final String scheduleId;
  final DateTime slotStartAt;
  final int slotDurationMinutes;
  final String centerId;
  final String provinceKey;
  final String cityKey;
  final String specialtyKey;
  final String specialtyEn;
  final String specialtyAr;
  final String specialtyKu;
  final String clinicName;

  const ConsultationDetail({
    super.key,
    required this.scheduleId,
    required this.slotStartAt,
    required this.slotDurationMinutes,
    required this.centerId,
    required this.provinceKey,
    required this.cityKey,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.doctorType,
    required this.doctorExp,

    // ⭐ ADD THESE
    required this.specialtyKey,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.specialtyKu,
    required this.clinicName,
    this.date,
    this.time,
  });

  @override
  State<ConsultationDetail> createState() => _ConsultationDetailState();
}

class _ConsultationDetailState extends State<ConsultationDetail> {
  final DatabaseService _dbService = DatabaseService.instance;
  String? userId;
  Patient? selectedPatient;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    await _dbService.initialize();
    setState(() => userId = _dbService.userId);
  }

  Future<void> _addPatientModal() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: fixPadding * 2,
            right: fixPadding * 2,
            top: fixPadding * 2,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Patient', style: blackBigBoldTextStyle),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (Years)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameController.text.trim().isEmpty) return;
                            setModalState(() => isSaving = true);
                            try {
                              await _dbService.createPatient({
                                'name': nameController.text.trim(),
                                'age': int.tryParse(ageController.text) ?? 0,
                                'isSelf': false,
                                'image': 'https://via.placeholder.com/150'
                              });
                              if (mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Patient'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _createAppointment() async {
    if (selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      //----------------------------------------
      // 🔥 REQUIRED SLOT DATA
      // These MUST be passed from DoctorTimeSlot
      //----------------------------------------

      final scheduleId = widget.scheduleId;
      final slotStartAt = widget.slotStartAt;
      final duration = widget.slotDurationMinutes;

      //----------------------------------------

      await AppointmentBuilder.create(
        scheduleId: scheduleId,

        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        doctorImage: widget.doctorImage,

        patientId: selectedPatient!.id,
        patientName: selectedPatient!.name,

        // if you have it
        relationship: selectedPatient!.isSelf ? null : "family",

        slotStartAt: slotStartAt,

        source: "patient_app",
        bookedByUserId: user.uid,
        bookedByRole: "patient",
        bookedByName: selectedPatient!.name,
      );

      //----------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: const BottomBar(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        title: Text('Consultation Detail', style: appBarTitleTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(fixPadding * 2),
        child: ElevatedButton(
          onPressed: _isBooking ? null : _createAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isBooking
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Confirm Booking', style: whiteColorButtonTextStyle),
        ),
      ),
      body: Column(
        children: [
          _buildDoctorSummary(),
          Expanded(child: _buildPatientsList()),
        ],
      ),
    );
  }

  Widget _buildDoctorSummary() {
    return Container(
      padding: EdgeInsets.all(fixPadding * 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: widget.doctorImage,
            child: CircleAvatar(
              radius: 40,
              backgroundImage: widget.doctorImage.startsWith('http')
                  ? NetworkImage(widget.doctorImage)
                  : AssetImage(widget.doctorImage) as ImageProvider,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. ${widget.doctorName}',
                    style: blackNormalBoldTextStyle),
                const SizedBox(height: 5),
                Text(widget.doctorType, style: greyNormalTextStyle),
                const SizedBox(height: 5),
                Text('${widget.doctorExp} Years Experience',
                    style: primaryColorNormalTextStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 18, color: greyColor),
                    const SizedBox(width: 6),
                    Text(widget.date ?? 'Date N/A',
                        style: blackNormalTextStyle),
                    const SizedBox(width: 20),
                    Icon(Icons.access_time, size: 18, color: greyColor),
                    const SizedBox(width: 6),
                    Text(widget.time ?? 'Time N/A',
                        style: blackNormalTextStyle),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .where('userId', isEqualTo: _dbService.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final patients = snapshot.data?.docs
                .map((doc) => Patient.fromFirestore(doc))
                .toList() ??
            [];

        return ListView(
          padding: EdgeInsets.all(fixPadding * 2),
          children: [
            Text('Select Patient', style: blackBigBoldTextStyle),
            const SizedBox(height: 15),
            if (patients.isEmpty)
              const Center(child: Text('No patients found. Add one below.')),
            ...patients.map((p) => _buildPatientTile(p)),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: _addPatientModal,
              icon: Icon(Icons.add_circle, color: primaryColor),
              label: Text('Add a Dependent Patient',
                  style: primaryColorNormalBoldTextStyle),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientTile(Patient patient) {
    final isSelected = selectedPatient?.id == patient.id;
    return InkWell(
      onTap: () => setState(() => selectedPatient = patient),
      child: Container(
        margin: EdgeInsets.only(bottom: fixPadding),
        padding: EdgeInsets.all(fixPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(fixPadding),
          border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: 1.3),
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: patient.avatarUrl != null
                  ? NetworkImage(patient.avatarUrl!)
                  : const AssetImage('assets/doctor_default.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                patient.isSelf ? '${patient.name} (You)' : patient.name,
                style: blackNormalBoldTextStyle,
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
