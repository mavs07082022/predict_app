import 'package:flutter/material.dart';

class CropReference {
  final String source, ideal, url;
  CropReference({required this.source, required this.ideal, required this.url});
  factory CropReference.fromJson(Map<String, dynamic> j) => CropReference(
        source: j['source'] as String,
        ideal: j['ideal'] as String,
        url: j['url'] as String,
      );
}

class CropRank {
  final String crop, trend;
  final double score;
  final CropReference reference;

  CropRank({required this.crop, required this.score, required this.trend, required this.reference});

  factory CropRank.fromJson(Map<String, dynamic> j) => CropRank(
        crop: j['crop'] as String,
        score: (j['score'] as num).toDouble(),
        trend: j['trend'] as String? ?? 'new',
        reference: CropReference.fromJson(j['reference'] as Map<String, dynamic>),
      );

  String get displayName => crop.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  String get emoji => const {'rice': '🌾', 'corn': '🌽', 'cassava': '🥔', 'eggplant': '🍆', 'tomato': '🍅', 'string_beans': '🫘'}[crop] ?? '🌱';
  Color get color => score >= 70 ? const Color(0xFF2E7D32) : score >= 40 ? const Color(0xFFF57C00) : const Color(0xFFC62828);
}

class ZonePrediction {
  final int id, readingCount;
  final String name, soilType, sensorId, status, aiAdvice;
  final double areaSqm;
  final DateTime lastUpdated;
  final List<CropRank> rankings;
  
  final double smN, smP, smK, smPh, smMoisture, smSoilTemp, smAirTemp;

  ZonePrediction({
    required this.id, required this.name, required this.soilType,
    required this.areaSqm, required this.sensorId, required this.lastUpdated,
    required this.status, required this.rankings, required this.aiAdvice,
    required this.smN, required this.smP, required this.smK,
    required this.smPh, required this.smMoisture, required this.smSoilTemp,
    required this.smAirTemp, required this.readingCount,
  });

  CropRank? get topPick => rankings.isEmpty ? null : rankings.first;

  factory ZonePrediction.fromJson(Map<String, dynamic> z, Map<String, dynamic> p) {
    return ZonePrediction(
      id: z['id'] as int,
      name: z['name'] as String,
      soilType: z['soil_type'] as String,
      areaSqm: (z['area_sqm'] as num).toDouble(),
      sensorId: z['sensor_id'] as String,
      lastUpdated: DateTime.tryParse(p['last_updated'] as String? ?? '') ?? DateTime.now(),
      status: p['status'] as String? ?? 'updating',
      aiAdvice: p['ai_advice'] as String? ?? '',
      rankings: ((p['rankings'] as List?) ?? []).map((e) => CropRank.fromJson(e as Map<String, dynamic>)).toList(),
      smN: (p['sm_n'] as num?)?.toDouble() ?? 0.0,
      smP: (p['sm_p'] as num?)?.toDouble() ?? 0.0,
      smK: (p['sm_k'] as num?)?.toDouble() ?? 0.0,
      smPh: (p['sm_ph'] as num?)?.toDouble() ?? 0.0,
      smMoisture: (p['sm_moisture'] as num?)?.toDouble() ?? 0.0,
      smSoilTemp: (p['sm_soil_temp'] as num?)?.toDouble() ?? 0.0,
      smAirTemp: (p['sm_air_temp'] as num?)?.toDouble() ?? 0.0,
      readingCount: (p['reading_count'] as num?)?.toInt() ?? 0,
    );
  }
}