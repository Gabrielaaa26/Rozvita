// Importuri necesare pentru funcționalitatea ecranului principal
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_screen.dart';
import 'pulse_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../ble_connection_manager.dart';

/// Ecranul principal al aplicației
/// Afișează meniul principal cu toate funcționalitățile disponibile
class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  /// Obține datele utilizatorului din Firestore
  /// Returnează un Map cu datele utilizatorului sau null dacă nu există
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  /// Deconectează utilizatorul curent
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  /// Navigare către ecranul de scanare BLE
  void _goToScanScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  /// Navigare către ecranul de măsurare puls
  /// Verifică dacă există o conexiune BLE activă
  void _goToPulseScreen(BuildContext context) {
    final manager = BleConnectionManager();
    if (manager.connectedDevice != null && manager.heartRateChar != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PulseScreen(
            connectedDevice: manager.connectedDevice!,
            heartRateChar: manager.heartRateChar!,
          ),
        ),
      );
    } else {
      // Afișează mesaj dacă nu există conexiune
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu este nici un device conectat')),
      );
    }
  }

  /// Navigare către ecranul de istoric
  void _goToHistoryScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  /// Navigare către ecranul de profil
  void _goToProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Utilizator';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      // Bara de sus cu titlu și buton de deconectare
      appBar: AppBar(
        title: const Text("RozVita Health"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepPurple),
            onPressed: () => _logout(context),
            tooltip: 'Deconectare',
          ),
        ],
      ),
      // Conținutul principal cu scroll
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header cu gradient și informații utilizator
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              // Încarcă și afișează datele utilizatorului
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  final profileImageUrl = userData?['profileImage'];
                  final name = userData?['name'] ?? userEmail;
                  
                  return Row(
                    children: [
                      // Avatar cu imagine de profil sau icon implicit
                      GestureDetector(
                        onTap: () => _goToProfileScreen(context),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(Icons.person, color: Colors.deepPurple, size: 36)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Informații utilizator (nume și email)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bine ai venit, $name!",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userEmail,
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Meniul principal cu carduri pentru fiecare funcționalitate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Card pentru scanare BLE
                  _MenuCard(
                    icon: Icons.bluetooth_searching,
                    title: "Scanare și conectare BLE",
                    color: Colors.deepPurpleAccent,
                    onTap: () => _goToScanScreen(context),
                  ),
                  const SizedBox(height: 20),
                  // Card pentru vizualizare puls
                  _MenuCard(
                    icon: Icons.monitor_heart,
                    title: "Vezi pulsul",
                    color: Colors.pinkAccent,
                    onTap: () => _goToPulseScreen(context),
                  ),
                  const SizedBox(height: 20),
                  // Card pentru istoric pulsuri
                  _MenuCard(
                    icon: Icons.history,
                    title: "Istoric pulsuri",
                    color: Colors.teal,
                    onTap: () => _goToHistoryScreen(context),
                  ),
                  const SizedBox(height: 20),
                  // Card pentru profil
                  _MenuCard(
                    icon: Icons.person,
                    title: "Profil",
                    color: Colors.blue,
                    onTap: () => _goToProfileScreen(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pentru cardurile din meniu
/// Afișează un card cu icon, titlu și culoare personalizată
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
