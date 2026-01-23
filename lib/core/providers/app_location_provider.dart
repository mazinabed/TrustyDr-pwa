// lib/core/providers/app_location_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocation {
  final String provinceKey;
  final String cityEn;

  const AppLocation({
    required this.provinceKey,
    required this.cityEn,
  });
}

class AppLocationNotifier extends Notifier<AppLocation?> {
  @override
  AppLocation? build() => null;

  void setLocation({
    required String provinceKey,
    required String cityEn,
  }) {
    state = AppLocation(
      provinceKey: provinceKey,
      cityEn: cityEn,
    );
  }
}

final appLocationProvider = NotifierProvider<AppLocationNotifier, AppLocation?>(
    AppLocationNotifier.new);
