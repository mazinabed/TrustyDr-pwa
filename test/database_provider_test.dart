import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/database_provider.dart';
import 'package:trustydr/core/services/database_service_contract.dart';

class _MockDb implements DatabaseServiceContract {
  @override
  bool get isInitialized => true;

  @override
  String? get userId => 'mock-user';

  @override
  Future<void> initialize() async {}

  @override
  Future<String> createPatient(Map<String, dynamic> data) async => 'mockId';
}

void main() {
  test('databaseServiceProvider can be overridden with a mock', () async {
    final mock = _MockDb();
    final container = ProviderContainer(overrides: [
      databaseServiceProvider.overrideWithValue(mock),
    ]);

    final svc = container.read(databaseServiceProvider);
    expect(svc, same(mock));

    final id = await svc.createPatient({'name': 'test'});
    expect(id, 'mockId');

    container.dispose();
  });
}
