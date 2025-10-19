// Importuri necesare pentru funcționalitatea de bază
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';
import 'screens/home_menu_screen.dart';
import 'firebase_options.dart';

/// Punctul de intrare în aplicație
/// Inițializează Firebase și pornește aplicația Flutter
void main() async {
  // Asigură inițializarea corectă a Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Inițializează Firebase cu opțiunile specifice platformei
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Pornește aplicația
  runApp(const MyApp());
}

/// Clasa principală a aplicației
/// Definește tema și configurația de bază
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RozVita',
      debugShowCheckedModeBanner: false, // Ascunde banner-ul de debug
      theme: ThemeData(
        primarySwatch: Colors.pink, // Setează culoarea principală roz
      ),
      home: const AuthGate(), // Începe cu verificarea autentificării
    );
  }
}

/// Poarta de autentificare a aplicației
/// Gestionează starea de autentificare și redirecționează către ecranul corespunzător
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascultă schimbările stării de autentificare
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Afișează indicator de încărcare în timpul verificării
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Dacă utilizatorul este autentificat, afișează meniul principal
        else if (snapshot.hasData) {
          return const HomeMenuScreen();
        }
        // Dacă utilizatorul nu este autentificat, afișează ecranul de login
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
