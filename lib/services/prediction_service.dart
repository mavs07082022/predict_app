import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/zone_prediction.dart';

class PredictionService {
  static const String _base = 'http://10.42.0.1:8001';

  Future<List<ZonePrediction>> fetchAll() async {
    final z = await http.get(Uri.parse('$_base/api/zones/')).timeout(const Duration(seconds: 8));
    if (z.statusCode != 200) throw Exception('Zones request failed: ${z.statusCode}');

    final zones = jsonDecode(z.body) as List;
    final out = <ZonePrediction>[];

    for (final zone in zones) {
      try {
        final p = await http.get(Uri.parse('$_base/api/predict/${zone['id']}')).timeout(const Duration(seconds: 8));
        out.add(ZonePrediction.fromJson(
          zone as Map<String, dynamic>,
          p.statusCode == 200 ? jsonDecode(p.body) as Map<String, dynamic> : {},
        ));
      } catch (_) {
        out.add(ZonePrediction.fromJson(zone as Map<String, dynamic>, {}));
      }
    }
    return out;
  }
}