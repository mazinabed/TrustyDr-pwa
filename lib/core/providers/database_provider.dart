import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/services/database_service_contract.dart';
import 'package:trustydr/core/services/database_service_adapter.dart';

/// Provides the app DatabaseService contract. In production this returns an
/// adapter that delegates to the existing singleton. Tests can override this
/// provider with a mock implementation.
final databaseServiceProvider = Provider<DatabaseServiceContract>(
  (ref) => DatabaseServiceAdapter(),
);
