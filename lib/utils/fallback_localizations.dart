import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return DefaultMaterialLocalizations();
  }

  @override
  bool shouldReload(_) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return DefaultCupertinoLocalizations();
  }

  @override
  bool shouldReload(_) => false;
}
