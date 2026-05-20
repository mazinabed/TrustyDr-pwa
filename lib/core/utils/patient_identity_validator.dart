class PatientIdentityValidator {
  PatientIdentityValidator._();

  static const _minLength = 2;

  // Generic/default names rejected in EN, AR, KU
  static const _placeholders = <String>{
    // English
    'user', 'patient', 'guest', 'username', 'name',
    // Arabic
    'مستخدم', 'مستخدم تجريبي', 'مستخدم جديد', 'اسم',
    // Kurdish
    'نووسیار', 'کاربەر', 'ناو',
  };

  /// Returns true only when [name] is a plausible real name.
  /// Rejects: null, blank, too short, no Unicode letter, known placeholder.
  static bool isValidName(String? name) {
    if (name == null) return false;
    final trimmed = name.trim();
    if (trimmed.length < _minLength) return false;
    if (!trimmed.contains(RegExp(r'\p{L}', unicode: true))) return false;
    if (_placeholders.contains(trimmed.toLowerCase())) return false;
    return true;
  }
}
