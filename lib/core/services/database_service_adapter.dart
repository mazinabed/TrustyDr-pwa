import 'package:trustydr/core/services/database_service_contract.dart';
import 'package:trustydr/services/database_service.dart';

class DatabaseServiceAdapter implements DatabaseServiceContract {
  final DatabaseService _svc = DatabaseService.instance;

  @override
  bool get isInitialized => _svc.isInitialized;

  @override
  String? get userId => _svc.userId;

  @override
  Future<void> initialize() => _svc.initialize();

  @override
  Future<String> createPatient(Map<String, dynamic> data) =>
      _svc.createPatient(data);
}
