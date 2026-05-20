class DailyHealthWeather {
  final String provinceKey;
  final String provinceEn;
  final String provinceAr;
  final String provinceKu;
  final String date;
  final bool isStale;
  final int? tempC;
  final int? feelsLikeC;
  final double uvIndex;
  final String uvCategory;
  final int aqi;
  final String aqiCategory;
  final int? pm10;
  final int dustUgm3;
  final String dustCategory;
  final int windSpeedKmh;
  final String windCategory;
  final String weatherSummaryKey;
  final String healthSignal;
  final String advisoryKey;
  final bool adviseHydration;
  final bool adviseUVProtection;
  final bool adviseReduceOutdoor;
  final bool adviseSensitiveGroups;
  final bool adviseDustMask;

  const DailyHealthWeather({
    required this.provinceKey,
    required this.provinceEn,
    required this.provinceAr,
    required this.provinceKu,
    required this.date,
    required this.isStale,
    this.tempC,
    this.feelsLikeC,
    required this.uvIndex,
    required this.uvCategory,
    required this.aqi,
    required this.aqiCategory,
    this.pm10,
    required this.dustUgm3,
    required this.dustCategory,
    required this.windSpeedKmh,
    required this.windCategory,
    required this.weatherSummaryKey,
    required this.healthSignal,
    required this.advisoryKey,
    required this.adviseHydration,
    required this.adviseUVProtection,
    required this.adviseReduceOutdoor,
    required this.adviseSensitiveGroups,
    required this.adviseDustMask,
  });

  factory DailyHealthWeather.fromMap(Map<String, dynamic> d) {
    return DailyHealthWeather(
      provinceKey: (d['provinceKey'] ?? '').toString(),
      provinceEn: (d['province_en'] ?? '').toString(),
      provinceAr: (d['province_ar'] ?? '').toString(),
      provinceKu: (d['province_ku'] ?? '').toString(),
      date: (d['date'] ?? '').toString(),
      isStale: (d['isStale'] as bool?) ?? false,
      tempC: (d['tempC'] as num?)?.toInt(),
      feelsLikeC: (d['feelsLikeC'] as num?)?.toInt(),
      uvIndex: (d['uvIndex'] as num?)?.toDouble() ?? 0.0,
      uvCategory: (d['uvCategory'] ?? 'low').toString(),
      aqi: (d['aqi'] as num?)?.toInt() ?? 0,
      aqiCategory: (d['aqiCategory'] ?? 'good').toString(),
      pm10: (d['pm10'] as num?)?.toInt(),
      dustUgm3: (d['dustUgm3'] as num?)?.toInt() ?? 0,
      dustCategory: (d['dustCategory'] ?? 'low').toString(),
      windSpeedKmh: (d['windSpeedKmh'] as num?)?.toInt() ?? 0,
      windCategory: (d['windCategory'] ?? 'calm').toString(),
      weatherSummaryKey: (d['weatherSummaryKey'] ?? 'clear').toString(),
      healthSignal: (d['healthSignal'] ?? 'safe').toString(),
      advisoryKey: (d['advisoryKey'] ?? 'normal').toString(),
      adviseHydration: (d['adviseHydration'] as bool?) ?? false,
      adviseUVProtection: (d['adviseUVProtection'] as bool?) ?? false,
      adviseReduceOutdoor: (d['adviseReduceOutdoor'] as bool?) ?? false,
      adviseSensitiveGroups: (d['adviseSensitiveGroups'] as bool?) ?? false,
      adviseDustMask: (d['adviseDustMask'] as bool?) ?? false,
    );
  }
}
