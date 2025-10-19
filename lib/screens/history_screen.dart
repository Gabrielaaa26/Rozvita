// Importuri necesare pentru funcționalitatea de istoric
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Ecranul de istoric al pulsului
/// Afișează un grafic și o listă cu istoricul măsurătorilor
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// Starea ecranului de istoric
class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _pulseData = []; // Lista măsurătorilor
  bool _isLoading = true;                     // Indicator de încărcare
  String _errorMessage = '';                  // Mesaj de eroare

  @override
  void initState() {
    super.initState();
    _loadPulseData(); // Încarcă datele la inițializare
  }

  /// Calculează valoarea minimă pentru axa Y a graficului
  double _getMinY() {
    if (_pulseData.isEmpty) return 40;
    double minPulse = double.infinity;
    for (var data in _pulseData) {
      final pulse = (data['pulse'] as num).toDouble();
      if (pulse < minPulse) minPulse = pulse;
    }
    // Rotunjește în jos la cel mai apropiat multiplu de 10
    return (minPulse ~/ 10) * 10.0;
  }

  /// Încarcă datele despre puls din Firestore
  Future<void> _loadPulseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Nu sunteți autentificat';
          _isLoading = false;
        });
        return;
      }

      // Obține ultimele 30 de măsurători din Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pulsuri')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      // Procesează datele și elimină măsurătorile cu valoarea 0
      final data = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'pulse': data['bpm'] as num,
          'timestamp': data['timestamp'] as Timestamp,
          'id': doc.id,
        };
      }).where((measurement) => (measurement['pulse'] as num) > 0).toList();

      setState(() {
        _pulseData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Eroare la încărcarea datelor: $e');
      setState(() {
        _errorMessage = 'Eroare la încărcarea datelor: $e';
        _isLoading = false;
      });
    }
  }

  /// Șterge tot istoricul măsurătorilor
  Future<void> _deleteHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nu sunteți autentificat')),
        );
        return;
      }

      // Dialog de confirmare
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Șterge Istoric'),
          content: const Text('Sigur doriți să ștergeți tot istoricul pulsului?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anulare'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Șterge'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isLoading = true);

      // Șterge fiecare document din Firestore
      for (var measurement in _pulseData) {
        await FirebaseFirestore.instance
            .collection('pulsuri')
            .doc(measurement['id'])
            .delete();
      }

      setState(() {
        _pulseData = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Istoricul a fost șters')),
        );
      }
    } catch (e) {
      print('Eroare la ștergerea istoricului: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eroare la ștergerea istoricului')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Generează punctele pentru grafic
  List<FlSpot> _getSpots() {
    if (_pulseData.isEmpty) return [];
    
    // Creează punctele de la cele mai noi la cele mai vechi
    final reversed = _pulseData.reversed.toList();
    return reversed.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['pulse'].toDouble());
    }).toList(); // Acum x=0 va fi cel mai vechi, iar x=length-1 cel mai nou
  }

  /// Construiește widgetul pentru grafic
  Widget _buildChart() {
    // Afișează un mesaj dacă nu există date
    if (_pulseData.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Evoluția pulsului',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB993D6),
                ),
              ),
              const SizedBox(height: 24),
              Icon(Icons.timeline_outlined, 
                size: 48, 
                color: Colors.grey[400]
              ),
              const SizedBox(height: 16),
              Text(
                'Nu există măsurători valide',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    // Construiește cardul cu graficul
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evoluția pulsului',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB993D6),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFB993D6).withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFB993D6).withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: (_pulseData.length - 1).toDouble(),
                  minY: _getMinY(),
                  maxY: 150,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getSpots(),
                      isCurved: true,
                      color: const Color(0xFFB993D6),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 2.5,
                            color: Colors.white,
                            strokeWidth: 1.5,
                            strokeColor: const Color(0xFFB993D6),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFB993D6).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construiește lista cu măsurători
  Widget _buildList() {
    if (_pulseData.isEmpty) {
      return const SizedBox.shrink(); // Nu afișa secțiunea listei când nu sunt date valide
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pulseData.length,
      itemBuilder: (context, index) {
        final measurement = _pulseData[index];
        final pulse = measurement['pulse'];
        final timestamp = (measurement['timestamp'] as Timestamp).toDate();
        final timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
        final dateString = '${timestamp.day}/${timestamp.month}/${timestamp.year}';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.favorite,
              color: _getPulseColor(pulse.toDouble()),
            ),
            title: Text(
              '$pulse BPM',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              '$timeString - $dateString',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: _getPulseStatus(pulse.toDouble()),
          ),
        );
      },
    );
  }

  /// Obține culoarea corespunzătoare pentru valoarea pulsului
  Color _getPulseColor(double pulse) {
    if (pulse < 60) return Colors.blue;
    if (pulse > 100) return Colors.red;
    return Colors.green;
  }

  /// Obține statusul corespunzător pentru valoarea pulsului
  Widget _getPulseStatus(double pulse) {
    String status;
    Color color;

    if (pulse < 60) {
      status = 'Scăzut';
      color = Colors.blue;
    } else if (pulse > 100) {
      status = 'Ridicat';
      color = Colors.red;
    } else {
      status = 'Normal';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Istoric Pulsuri'),
        backgroundColor: const Color(0xFFB993D6),
        actions: [
          if (_pulseData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteHistory,
              tooltip: 'Șterge istoricul',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB993D6)),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPulseData,
                  color: const Color(0xFFB993D6),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildChart(),
                        _buildList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
