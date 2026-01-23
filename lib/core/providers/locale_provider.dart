import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

final localeProvider = StateProvider<Locale?>((ref) => null);

/// Example: ref.read(localeProvider.notifier).state = const Locale('ar');
