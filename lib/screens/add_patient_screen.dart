import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/core/services/database_service_contract.dart';
import 'package:trustydr/core/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  late final DatabaseServiceContract _dbService;

  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // read the provider once and keep a local reference for this screen
    _dbService = ref.read(databaseServiceProvider);
  }

  Future<void> _addPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Attempting to save patient...';
    });

    try {
      if (!_dbService.isInitialized) {
        await _dbService.initialize();
      }

      if (_dbService.userId == null) {
        throw Exception('User is not authenticated. Cannot save data.');
      }

      _statusMessage = null;

      final patientData = {
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isSelf': false,
        'image': 'https://via.placeholder.com/150',
      };

      await _dbService.createPatient(patientData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Patient "${_nameController.text}" added successfully!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to add patient: '
              '${e.toString().contains('Exception:') ? e.toString().split('Exception:').last.trim() : e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Patient',
          style: appBarTitleTextStyle.copyWith(
            color: PatientAppColors.brandIndigo,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PatientAppColors.brandIndigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(fixPadding * 2.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Register Patient Details', style: blackBigBoldTextStyle),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the patient\'s name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age (Years)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the patient\'s age.';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Age must be a valid number greater than 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.contains('Failed') ||
                                _statusMessage!.contains('Error')
                            ? Colors.red
                            : PatientAppColors.brandIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatientAppColors.brandIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'Save Patient',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
