// Strips generic doctor-title tokens from a search query so that
// "Dr Ahmed" → "Ahmed" and "دکتۆر ئەحمەد" → "ئەحمەد".
String stripDoctorTitles(String query) {
  const titles = {
    'doctor',
    'dr',
    'dr.',
    'د',
    'د.',
    'دكتور',
    'دكتورة',
    'طبيب',
    'طبيبة',
    'دکتۆر',
    'پزیشک',
  };
  final parts = query.trim().split(RegExp(r'\s+'));
  return parts.where((p) => !titles.contains(p.toLowerCase())).join(' ').trim();
}

// Routes to the appropriate Firestore lowercase field based on detected script.
// Kurdish-specific chars take priority over generic Arabic-range chars.
String nameSearchField(String q) {
  const kurdish = {'ئ', 'ڕ', 'ڵ', 'ۆ', 'ێ', 'ە', 'گ', 'چ', 'پ', 'ژ', 'ڤ'};
  for (final c in q.runes) {
    if (kurdish.contains(String.fromCharCode(c))) return 'name_ku_lower';
  }
  for (final c in q.runes) {
    if (c >= 0x0600 && c <= 0x06FF) return 'name_ar_lower';
  }
  return 'name_lower';
}
