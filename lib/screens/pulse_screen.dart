// Importuri necesare pentru funcționalitatea de măsurare a pulsului
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Ecranul de măsurare a pulsului
/// Afișează pulsul în timp real și istoricul recent
class PulseScreen extends StatefulWidget {
  final BluetoothDevice connectedDevice;        // Dispozitivul BLE conectat
  final BluetoothCharacteristic heartRateChar;  // Caracteristica BLE pentru puls

  const PulseScreen({
    super.key,
    required this.connectedDevice,
    required this.heartRateChar
  });

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

/// Starea ecranului de măsurare a pulsului
class _PulseScreenState extends State<PulseScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int? bpm;                    // Valoarea curentă a pulsului
  List<int> bpmHistory = [];   // Istoricul măsurătorilor
  String status = "🔊 Asteapta datele...";  // Starea curentă

  // Controlere pentru animații
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBpmHistoryFromFirebase();  // Încarcă istoricul din Firebase
    
    // Inițializare animații
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _listenToHeartRate();  // Începe ascultarea datelor de puls
  }

  /// Încarcă istoricul măsurătorilor din Firebase
  Future<void> _loadBpmHistoryFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Obține ultimele 30 de măsurători
    final snapshot = await FirebaseFirestore.instance
        .collection('pulsuri')
        .where('uid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();
        
    setState(() {
      bpmHistory = snapshot.docs.map((doc) => (doc['bpm'] as int)).toList();
    });
  }

  /// Configurează ascultarea datelor de puls de la dispozitivul BLE
  void _listenToHeartRate() async {
    try {
      // Resetare și activare notificări
      await widget.heartRateChar.setNotifyValue(false);
      await widget.heartRateChar.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 100));

      // Ascultă stream-ul de date
      widget.heartRateChar.lastValueStream.listen((value) async {
        if (value.isNotEmpty && mounted) {
          // Decodare valoare puls din datele BLE
          int val;
          if ((value[0] & 0x01) != 0 && value.length > 2) {
            val = value[1] | (value[2] << 8);
          } else {
            val = value[1];
          }

          debugPrint("📥 Puls primit: $val");

          // Validare și salvare date
          if (val >= 0 && val < 220) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // Salvare în Firebase
              await FirebaseFirestore.instance.collection('pulsuri').add({
                'uid': user.uid,
                'bpm': val,
                'timestamp': Timestamp.now(),
              });
            }
            
            setState(() {
              if (val > 0) {
                bpm = val;
                status = "⏰ ${DateFormat('HH:mm:ss').format(DateTime.now())}";
                bpmHistory.add(val);
              } else {
                bpm = null;
                status = "⚠️ Nu este detectat pulsul";
              }
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Eroare la ascultare puls: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reîncarcă datele când aplicația revine în prim-plan
    if (state == AppLifecycleState.resumed) {
      _loadBpmHistoryFromFirebase();
    }
  }

  /// Construiește widgetul pentru afișarea stării pulsului
  Widget buildPulseStatus() {
    if (bpm == null) return const SizedBox.shrink();
    
    // Determină starea pulsului și setează culorile și iconițele corespunzătoare
    Color color;
    String text;
    IconData icon;
    if (bpm! < 100 && bpm! > 40) {
      color = Colors.green;
      text = 'Puls normal';
      icon = Icons.check_circle;
    } else if (bpm! >= 100) {
      color = Colors.redAccent;
      text = 'Puls ridicat';
      icon = Icons.warning_amber_rounded;
    } else {
      color = Colors.grey;
      text = 'Puls scăzut';
      icon = Icons.info_outline;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  /// Construiește cardul cu graficul evoluției pulsului
  Widget buildChartCard() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Evoluție puls (ultimele 30 măsurători)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade700,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Colors.deepPurple.withOpacity(0.04),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                // Graficul de evoluție a pulsului
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: bpmHistory.isEmpty
                      ? const Center(child: Text('Nu există date pentru grafic.',
                          style: TextStyle(color: Colors.grey)))
                      : LineChart(
                          LineChartData(
                            minY: 40,     // Valoarea minimă pe axa Y
                            maxY: 180,    // Valoarea maximă pe axa Y
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: bpmHistory
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                                    .toList(),
                                isCurved: true,
                                color: Colors.deepPurple,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.deepPurple.withOpacity(0.10),
                                ),
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 5,
                                    color: Colors.deepPurple,
                                    strokeWidth: 2,
                                    strokeColor: Colors.deepPurple.shade700,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(enabled: true),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Monitorizare puls"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleTextStyle: const TextStyle(color: Colors.deepPurple, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Card central cu puls și animație
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(Icons.favorite, size: 80, color: Colors.pinkAccent.shade100),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        bpm != null ? "$bpm BPM" : "-- BPM",
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        status,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Indicator status puls
              Card(
                elevation: 0,
                color: Colors.deepPurple.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: buildPulseStatus(),
                ),
              ),
              const SizedBox(height: 32),
              // Grafic fără chenar sau fundal alb/gradient
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 18), // padding mic sus, graficul urcat
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Evoluție puls (ultimele 30)",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: bpmHistory.isEmpty
                          ? const Center(child: Text('Nu există date pentru grafic.', style: TextStyle(color: Colors.grey)))
                          : LineChart(
                              LineChartData(
                                minY: 40,
                                maxY: 180,
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: bpmHistory
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.deepPurple,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.18),
                                          Colors.deepPurple.withOpacity(0.03)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                        radius: 2.5,
                                        color: Colors.deepPurple,
                                        strokeWidth: 1.2,
                                        strokeColor: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(enabled: true),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
