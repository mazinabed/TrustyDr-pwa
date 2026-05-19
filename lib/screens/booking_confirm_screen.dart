import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/services/database_service.dart';
import 'package:flutter/foundation.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String doctorType;
  final String doctorExp;

  const BookAppointmentScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.doctorType,
    required this.doctorExp,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _db = DatabaseService.instance;
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    locationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientAppColors.surface,
      appBar: AppBar(
        backgroundColor: PatientAppColors.brandIndigo,
        title: Text('Book Appointment', style: appBarWhiteTitleTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(fixPadding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorInfo(),
            const SizedBox(height: 30),
            _buildDateField(),
            const SizedBox(height: 20),
            _buildTimeField(),
            const SizedBox(height: 20),
            _buildLocationField(),
            const SizedBox(height: 20),
            _buildNotesField(),
            const SizedBox(height: 40),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: widget.doctorImage.startsWith('http')
              ? NetworkImage(widget.doctorImage)
              : AssetImage(widget.doctorImage) as ImageProvider,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. ${widget.doctorName}', style: blackNormalBoldTextStyle),
              const SizedBox(height: 5),
              Text(widget.doctorType, style: greyNormalTextStyle),
              const SizedBox(height: 5),
              Text('${widget.doctorExp} Years Experience',
                  style: primaryColorNormalTextStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTappableField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: blackNormalBoldTextStyle),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: fixPadding, vertical: fixPadding * 1.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(fixPadding),
              boxShadow: PatientAppColors.shadowSubtle,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: blackNormalTextStyle),
                Icon(icon, color: PatientAppColors.brandIndigo),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return _buildTappableField(
      label: 'Date',
      value: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
      icon: Icons.calendar_today,
      onTap: _pickDate,
    );
  }

  Widget _buildTimeField() {
    return _buildTappableField(
      label: 'Time',
      value: selectedTime.format(context),
      icon: Icons.access_time,
      onTap: _pickTime,
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: blackNormalBoldTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            hintText: 'Clinic or Hospital name',
            hintStyle: greySearchTextStyle,
            prefixIcon:
                Icon(Icons.location_on, color: PatientAppColors.brandIndigo),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fixPadding),
              borderSide: BorderSide.none,
            ),
          ),
          style: blackNormalTextStyle,
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes (Optional)', style: blackNormalBoldTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add any comments or notes...',
            hintStyle: greySearchTextStyle,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fixPadding),
              borderSide: BorderSide.none,
            ),
          ),
          style: blackNormalTextStyle,
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: PatientAppColors.brandIndigo,
          padding: EdgeInsets.symmetric(vertical: fixPadding * 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Confirm Booking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: PatientAppColors.brandIndigo,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: PatientAppColors.brandIndigo,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _bookAppointment() async {
    if (locationController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter the appointment location.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _db.initialize();

      final formattedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      final formattedTime = selectedTime.format(context);

      final appointmentData = {
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'doctorType': widget.doctorType,
        'date': formattedDate,
        'time': formattedTime,
        'location': locationController.text.trim(),
        'notes': notesController.text.trim(),
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _db.userId ?? 'anonymous',
        'patientId': 'patient_B',
      };

      await _db.createAppointment(appointmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointment confirmed successfully!',
              style: const TextStyle(color: Colors.white, fontSize: 15.0)),
          backgroundColor: PatientAppColors.statusConfirmed,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Appointment Save Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to book appointment: $e',
              style: const TextStyle(color: Colors.white, fontSize: 15.0)),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
