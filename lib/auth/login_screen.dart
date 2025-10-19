// Importuri necesare pentru autentificare și interfață
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

/// Ecranul de autentificare
/// Permite utilizatorilor să se autentifice cu email și parolă
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Starea ecranului de autentificare
/// Gestionează logica de autentificare și interfața utilizatorului
class _LoginScreenState extends State<LoginScreen> {
  // Controllere pentru câmpurile de text
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // Variabile pentru gestionarea stării
  bool isLoading = false;
  String error = '';
  String successMessage = '';

  /// Funcția de autentificare
  /// Procesează cererea de autentificare către Firebase
  Future<void> login() async {
    setState(() {
      isLoading = true;
      error = '';
      successMessage = '';
    });

    try {
      // Încearcă autentificarea cu email și parolă
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Gestionează erorile de autentificare
      setState(() {
        error = e.message ?? 'Eroare la autentificare';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Funcția de resetare a parolei
  /// Trimite un email de resetare a parolei
  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    
    // Validare email
    if (email.isEmpty) {
      setState(() {
        error = 'Vă rugăm să introduceți adresa de email pentru resetarea parolei';
        successMessage = '';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        error = 'Vă rugăm să introduceți o adresă de email validă';
        successMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
      successMessage = '';
    });

    try {
      // Trimite emailul de resetare
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      
      // Afișează dialog cu instrucțiuni
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email de resetare trimis'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Un email de resetare a fost trimis la: $email'),
                const SizedBox(height: 12),
                const Text('Vă rugăm să:'),
                const SizedBox(height: 8),
                const Text('1. Verificați și căsuța de spam'),
                const Text('2. Așteptați câteva minute dacă emailul nu apare imediat'),
                const Text('3. Asigurați-vă că adresa email este corectă'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
      setState(() {
        successMessage = 'Email de resetare trimis la $email';
        error = '';
      });
    } on FirebaseAuthException catch (e) {
      // Gestionează diferite tipuri de erori
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Adresa de email nu este validă';
          break;
        case 'user-not-found':
          errorMessage = 'Nu există cont asociat cu această adresă de email';
          break;
        case 'too-many-requests':
          errorMessage = 'Prea multe încercări. Vă rugăm să încercați mai târziu';
          break;
        default:
          errorMessage = 'Eroare: ${e.message ?? 'Eroare necunoscută'}';
      }
      setState(() {
        error = errorMessage;
        successMessage = '';
      });
    } catch (e) {
      setState(() {
        error = 'Eroare neașteptată: $e';
        successMessage = '';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      // Bara de sus cu titlul
      appBar: AppBar(
        title: const Text('Autentificare'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleTextStyle: const TextStyle(
            color: Colors.deepPurple,
            fontSize: 22,
            fontWeight: FontWeight.bold),
      ),
      // Conținutul principal
      body: Container(
        width: double.infinity,
        // Fundal cu gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: 28),
                // Formular de autentificare
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icoană lacăt
                    const Icon(Icons.lock,
                        size: 64, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 20),
                    // Câmp email
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Câmp parolă
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Parolă',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    // Afișare mesaje de eroare
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(error, 
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Afișare mesaje de succes
                    if (successMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(successMessage, 
                          style: const TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Butoane de acțiune
                    isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              // Buton autentificare
                              ElevatedButton.icon(
                                onPressed: login,
                                icon: const Icon(Icons.login),
                                label: const Text("Autentificare"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Buton resetare parolă
                              TextButton(
                                onPressed: resetPassword,
                                child: const Text(
                                  "Am uitat parola",
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 8),
                    // Link către înregistrare
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text("Nu ai cont? Creează unul!",
                          style: TextStyle(color: Colors.deepPurple)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
