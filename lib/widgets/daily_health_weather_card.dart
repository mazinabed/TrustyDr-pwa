import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/health_weather_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/daily_health_weather.dart';

class DailyHealthWeatherCard extends ConsumerWidget {
  final String? provinceKey;
  final VoidCallback? onSetLocation;

  const DailyHealthWeatherCard({
    super.key,
    this.provinceKey,
    this.onSetLocation,
  });

  static String _todayIraqDateStr() {
    final iraq = DateTime.now().toUtc().add(const Duration(hours: 3));
    final m = iraq.month.toString().padLeft(2, '0');
    final d = iraq.day.toString().padLeft(2, '0');
    return '${iraq.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = provinceKey ?? '';

    if (key.isEmpty) {
      return _wrapCard(child: _noLocationBody());
    }

    final weatherAsync = ref.watch(healthWeatherProvider(key));

    return _wrapCard(
      child: weatherAsync.when(
        loading: _loadingBody,
        error: (_, __) => _errorBody(),
        data: (w) => w == null ? _noDataBody() : _dataBody(w),
      ),
    );
  }

  Widget _wrapCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
          boxShadow: PatientAppColors.shadowCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _cardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0x1A4A90E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_outlined,
              size: 16,
              color: PatientAppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'health_weather.title'.tr(),
            style: const TextStyle(
              color: PatientAppColors.darkNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noLocationBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'health_weather.no_location'.tr(),
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSetLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x1A5CC6BA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'health_weather.set_location'.tr(),
                style: const TextStyle(
                  color: PatientAppColors.brandTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBody() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: PatientAppColors.brandTeal,
          ),
        ),
      ),
    );
  }

  Widget _errorBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Text(
        'health_weather.error'.tr(),
        style: const TextStyle(color: Colors.black45, fontSize: 13),
      ),
    );
  }

  Widget _noDataBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Text(
        'health_weather.no_data'.tr(),
        style: const TextStyle(color: Colors.black45, fontSize: 13),
      ),
    );
  }

  Widget _dataBody(DailyHealthWeather w) {
    final isStale = w.isStale || w.date != _todayIraqDateStr();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signal pill (left) + stacked temperature (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _signalPill(w.healthSignal),
              const Spacer(),
              if (w.tempC != null) _temperatureBlock(w),
            ],
          ),
          const SizedBox(height: 12),
          // Three metric chips: Dust | Air | UV or Heat
          _metricsRow(w),
          // Advisory awareness sentence
          if (w.advisoryKey != 'normal') ...[
            const SizedBox(height: 10),
            _advisoryBanner(w.advisoryKey),
          ],
          // Freshness footer — always shown
          const SizedBox(height: 10),
          _freshnessFooter(isStale),
        ],
      ),
    );
  }

  // Primary temp bold, feels-like subtle below — avoids weather-app side-by-side
  Widget _temperatureBlock(DailyHealthWeather w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${w.tempC}°C',
          style: const TextStyle(
            color: PatientAppColors.darkNavy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        if (w.feelsLikeC != null)
          Text(
            '${'health_weather.feels_like'.tr()} ${w.feelsLikeC}°',
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  // Teal dot + "Updated today" when fresh; amber warning when stale
  Widget _freshnessFooter(bool isStale) {
    if (isStale) {
      return Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 11,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            'health_weather.stale_notice'.tr(),
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 11,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: PatientAppColors.brandTeal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'health_weather.updated_today'.tr(),
          style: const TextStyle(
            color: Colors.black38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _signalPill(String signal) {
    final Color bg;
    final Color fg;
    final String labelKey;
    switch (signal) {
      case 'moderate':
        labelKey = 'health_weather.signal_moderate';
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF59E0B);
      case 'caution':
        labelKey = 'health_weather.signal_caution';
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFEF6C00);
      case 'hazardous':
        labelKey = 'health_weather.signal_hazardous';
        bg = const Color(0xFFFFEBEE);
        fg = PatientAppColors.statusCancelled;
      default:
        labelKey = 'health_weather.signal_safe';
        bg = const Color(0xFFE8F5E9);
        fg = PatientAppColors.statusConfirmed;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labelKey.tr(),
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _metricsRow(DailyHealthWeather w) {
    final feelsLikeC = w.feelsLikeC;
    final thirdChip = (feelsLikeC != null && feelsLikeC >= 30)
        ? _metricChip(
            icon: Icons.thermostat,
            label: 'health_weather.label_heat'.tr(),
            category: _heatCategoryLabel(feelsLikeC),
            rawValue: '$feelsLikeC°C',
            severity: _heatSeverity(feelsLikeC),
          )
        : _metricChip(
            icon: Icons.wb_sunny_outlined,
            label: 'health_weather.label_uv'.tr(),
            category: _categoryLabel(w.uvCategory),
            rawValue: w.uvIndex.toStringAsFixed(1),
            severity: _uvSeverity(w.uvCategory),
          );

    return Row(
      children: [
        _metricChip(
          icon: Icons.blur_on,
          label: 'health_weather.label_dust'.tr(),
          category: _categoryLabel(w.dustCategory),
          rawValue: '${w.dustUgm3} µg/m³',
          severity: _dustSeverity(w.dustCategory),
        ),
        const SizedBox(width: 8),
        _metricChip(
          icon: Icons.air,
          label: 'health_weather.label_aqi'.tr(),
          category: _categoryLabel(w.aqiCategory),
          rawValue: 'AQI ${w.aqi}',
          severity: _aqiSeverity(w.aqiCategory),
        ),
        const SizedBox(width: 8),
        thirdChip,
      ],
    );
  }

  // category = readable primary label; rawValue = subtle telemetry below
  Widget _metricChip({
    required IconData icon,
    required String label,
    required String category,
    required String rawValue,
    required _Severity severity,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: severity.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: severity.fg),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: severity.fg,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Human-readable category — primary
            Text(
              category,
              style: const TextStyle(
                color: PatientAppColors.darkNavy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // Raw value — subtle secondary
            Text(
              rawValue,
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _advisoryBanner(String advisoryKey) {
    final text = switch (advisoryKey) {
      'high_dust' => 'health_weather.advisory_high_dust'.tr(),
      'high_heat' => 'health_weather.advisory_high_heat'.tr(),
      'poor_air' => 'health_weather.advisory_poor_air'.tr(),
      'high_uv' => 'health_weather.advisory_high_uv'.tr(),
      'multi_risk' => 'health_weather.advisory_multi_risk'.tr(),
      _ => '',
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 13,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF7C5D00),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Maps backend category string → translated human-readable label
  String _categoryLabel(String category) => switch (category) {
        'good' => 'health_weather.cat_good'.tr(),
        'moderate' => 'health_weather.cat_moderate'.tr(),
        'low' => 'health_weather.cat_low'.tr(),
        'high' => 'health_weather.cat_high'.tr(),
        'very_high' => 'health_weather.cat_very_high'.tr(),
        'unhealthy_sensitive' => 'health_weather.cat_unhealthy_sensitive'.tr(),
        'unhealthy' => 'health_weather.cat_unhealthy'.tr(),
        'very_unhealthy' => 'health_weather.cat_very_unhealthy'.tr(),
        'hazardous' => 'health_weather.cat_hazardous'.tr(),
        'extreme' => 'health_weather.cat_extreme'.tr(),
        _ => category,
      };

  String _heatCategoryLabel(int feelsLikeC) {
    if (feelsLikeC >= 45) return 'health_weather.cat_extreme'.tr();
    if (feelsLikeC >= 38) return 'health_weather.cat_hot'.tr();
    return 'health_weather.cat_warm'.tr();
  }

  _Severity _dustSeverity(String category) => switch (category) {
        'moderate' => const _Severity(Color(0xFFFFF8E1), Color(0xFFF59E0B)),
        'high' => const _Severity(Color(0xFFFFF3E0), Color(0xFFEF6C00)),
        'very_high' =>
          const _Severity(Color(0xFFFFEBEE), PatientAppColors.statusCancelled),
        _ => const _Severity(Color(0xFFF3F8F6), PatientAppColors.brandTeal),
      };

  _Severity _aqiSeverity(String category) => switch (category) {
        'moderate' => const _Severity(Color(0xFFFFF8E1), Color(0xFFF59E0B)),
        'unhealthy_sensitive' ||
        'unhealthy' =>
          const _Severity(Color(0xFFFFF3E0), Color(0xFFEF6C00)),
        'very_unhealthy' ||
        'hazardous' =>
          const _Severity(Color(0xFFFFEBEE), PatientAppColors.statusCancelled),
        _ => const _Severity(Color(0xFFF3F8F6), PatientAppColors.brandTeal),
      };

  _Severity _uvSeverity(String category) => switch (category) {
        'moderate' => const _Severity(Color(0xFFFFF8E1), Color(0xFFF59E0B)),
        'high' => const _Severity(Color(0xFFFFF3E0), Color(0xFFEF6C00)),
        'very_high' ||
        'extreme' =>
          const _Severity(Color(0xFFFFEBEE), PatientAppColors.statusCancelled),
        _ => const _Severity(Color(0xFFF3F8F6), PatientAppColors.brandTeal),
      };

  _Severity _heatSeverity(int feelsLikeC) {
    if (feelsLikeC >= 45) {
      return const _Severity(
          Color(0xFFFFEBEE), PatientAppColors.statusCancelled);
    }
    if (feelsLikeC >= 38) {
      return const _Severity(Color(0xFFFFF3E0), Color(0xFFEF6C00));
    }
    return const _Severity(Color(0xFFFFF8E1), Color(0xFFF59E0B));
  }
}

class _Severity {
  final Color bg;
  final Color fg;

  const _Severity(this.bg, this.fg);
}
