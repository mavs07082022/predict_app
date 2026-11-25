import 'package:flutter/material.dart';
import '../models/zone_prediction.dart';
import '../services/prediction_service.dart';

class PredictionDashboardScreen extends StatefulWidget {
  const PredictionDashboardScreen({super.key});
  @override
  State<PredictionDashboardScreen> createState() => _State();
}

class _State extends State<PredictionDashboardScreen> {
  final _service = PredictionService();
  List<ZonePrediction> _zones = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastSync;

  // Startup Logic
  bool _isSystemReady = false;
  int _currentReadings = 0;
  final int _targetReadings = 10;

  @override
  void initState() {
    super.initState();
    _load();
    _autoRefresh();
  }

  void _autoRefresh() {
    Future.delayed(const Duration(seconds: 5), () { 
      if (!mounted) return;
      _load(silent: true);
      _autoRefresh();
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final fresh = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _zones = fresh;
        _loading = false;
        _error = null;
        _lastSync = DateTime.now();

        // Check if the system has collected 10 readings
        if (_zones.isNotEmpty) {
          _currentReadings = _zones[0].readingCount;
          if (_currentReadings >= _targetReadings) {
            _isSystemReady = true;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showCropDetails(BuildContext context, CropRank r, ZonePrediction z) {
    String survival = "";
    String reason = "";
    String action = "";

    if (r.score >= 70) {
      survival = "12 - 16 Weeks (Highly Viable)";
      reason = "The live sensor readings are a perfect match for the agronomic thresholds of ${r.displayName} in ${z.soilType} soil.";
      action = "Proceed with planting. Maintain current soil management.";
    } else if (r.score >= 50) {
      survival = "4 - 8 Weeks (Moderate Risk)";
      reason = "While ${z.soilType} soil can support ${r.displayName}, the current nutrients or pH are slightly outside the ideal range.";
      action = "Plant with caution. Monitor for nutrient deficiencies.";
    } else {
      survival = "1 - 3 Weeks (High Risk of Failure)";
      reason = "The live sensor data severely violates the required thresholds for ${r.displayName} in ${z.soilType} soil.";
      action = "Do NOT plant yet. Adjust soil nutrients and pH based on the warning banner.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(children: [
          Text(r.emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 8),
          Text(r.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: r.color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text("AI Score: ${r.score.toStringAsFixed(1)} pts", style: TextStyle(color: r.color, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("ESTIMATED SURVIVAL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(survival, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 16),
              const Text("Why is it in this rank?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(reason, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54)),
              const SizedBox(height: 16),
              const Text("AI Recommendation:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: r.color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: r.color.withOpacity(0.3))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(r.score >= 50 ? Icons.check_circle : Icons.warning, color: r.color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(action, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.color))),
                ]),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ─── STARTUP LOADING SCREEN (Blocks view until 10 readings) ───
    if (!_isSystemReady) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sensors, size: 80, color: Color(0xFF2E7D32)),
                const SizedBox(height: 24),
                const Text("Getting Stable Readings...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text("Please wait while the sensors calibrate the soil data for the AI model.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _currentReadings / _targetReadings, 
                    minHeight: 12, 
                    backgroundColor: Colors.green.shade100,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(height: 16),
                Text("$_currentReadings / $_targetReadings readings collected", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
        ),
      );
    }

    // ─── MAIN DASHBOARD SCREEN ───
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Crop Predictions', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          if (_lastSync != null)
            Center(child: Text('Synced ${_lastSync!.hour.toString().padLeft(2, '0')}:${_lastSync!.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10, color: Colors.grey))),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_zones.isNotEmpty) _summaryHeader(),
            ..._zones.map((z) => _zoneCard(z, context)),
          ],
        ),
      ),
    );
  }

  Widget _summaryHeader() {
    final best = _zones.isNotEmpty && _zones[0].topPick != null ? _zones[0].topPick!.displayName : '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farm Summary', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('${_zones.length}', 'Zones'),
              _stat('${_zones.where((z) => z.status == 'stable').length}', 'Stable'),
              _stat(best, 'Top Crop'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String val, String label) => Column(children: [
    Text(val, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800)),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85))),
  ]);

  Widget _zoneCard(ZonePrediction z, BuildContext ctx) {
    final top = z.topPick;
    final isSuitable = top != null && top.score >= 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: top?.color ?? Colors.grey),
                const SizedBox(width: 8),
                Text(z.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                _soilBadge(z.soilType),
              ],
            ),
            const SizedBox(height: 12),

            // LIVE SENSOR DATA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Row(children: [Icon(Icons.sensors, size: 14, color: Colors.blue), SizedBox(width: 6), Text('LIVE ENVIRONMENT (Real-Time)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blue))]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sensorVal('N', z.smN.toStringAsFixed(0), 'mg/kg', Colors.green),
                      _sensorVal('P', z.smP.toStringAsFixed(0), 'mg/kg', Colors.orange),
                      _sensorVal('K', z.smK.toStringAsFixed(0), 'mg/kg', Colors.purple),
                      _sensorVal('pH', z.smPh.toStringAsFixed(1), '', Colors.blue),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sensorVal('Moisture', '${z.smMoisture.toStringAsFixed(1)}%', '', Colors.cyan),
                      _sensorVal('Soil Temp', '${z.smSoilTemp.toStringAsFixed(1)}°C', '', Colors.deepOrange),
                      _sensorVal('Air Temp', '${z.smAirTemp.toStringAsFixed(1)}°C', '', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // AI ADVICE / WARNING BANNER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSuitable ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(color: isSuitable ? Colors.green : Colors.red),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(isSuitable ? Icons.check_circle : Icons.warning, color: isSuitable ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(z.aiAdvice, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSuitable ? Colors.green.shade900 : Colors.red.shade900)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            const Text('Full ranking — Tap a crop for details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
            const SizedBox(height: 4),

            // RANKINGS (CLICKABLE)
            ...z.rankings.asMap().entries.map((e) => InkWell(
              onTap: () => _showCropDetails(ctx, e.value, z),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24, alignment: Alignment.center,
                      decoration: BoxDecoration(color: e.key == 0 ? e.value.color : Colors.grey.shade200, borderRadius: BorderRadius.circular(7)),
                      child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: e.key == 0 ? Colors.white : Colors.grey.shade700)),
                    ),
                    const SizedBox(width: 10),
                    Text(e.value.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(e.value.reference.source, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(e.value.score.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w800, color: e.value.color, fontSize: 15)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _sensorVal(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _soilBadge(String t) {
    final colors = {
      'loam':  [const Color(0xFF6D4C41), const Color(0xFF8D6E63)],
      'clay':  [const Color(0xFF37474F), const Color(0xFF546E7A)],
      'sandy': [const Color(0xFFF9A825), const Color(0xFFFFB300)],
    }[t.toLowerCase()] ?? [Colors.grey, Colors.blueGrey];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(t == 'loam' ? Icons.grass : t == 'clay' ? Icons.water_drop : Icons.landscape, color: Colors.white, size: 12),
        const SizedBox(width: 5),
        Text('${t.toUpperCase()} SOIL', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      ]),
    );
  }
}