abstract class DatabaseServiceContract {
  bool get isInitialized;
  String? get userId;

  Future<void> initialize();

  /// Creates a patient record and returns the created document id.
  Future<String> createPatient(Map<String, dynamic> data);
}
