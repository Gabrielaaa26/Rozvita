// Importuri necesare pentru înregistrare și interfață
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Ecranul de înregistrare
/// Permite utilizatorilor să-și creeze un cont nou
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// Starea ecranului de înregistrare
/// Gestionează logica de înregistrare și interfața utilizatorului
class _RegisterScreenState extends State<RegisterScreen> {
  // Controllere pentru câmpurile de text
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // Variabilă pentru mesajul de eroare
  String error = '';

  /// Funcția de înregistrare
  /// Creează un cont nou în Firebase Authentication și document în Firestore
  Future<void> _register() async {
    try {
      // Încearcă să creeze contul nou
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      // Creează documentul utilizatorului în Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': emailController.text.trim(),
        'createdAt': Timestamp.now(),
        'name': '',
        'age': 0,
        'height': 0,
        'weight': 0,
        'profileImage': null,
      });
      
      // După înregistrare, deconectează și revino la login
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pop(context);
        // Afișează mesaj de succes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cont creat cu succes! Vă puteți autentifica acum.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Afișează eroarea dacă înregistrarea eșuează
      setState(() => error = e.message ?? 'Eroare necunoscută');
    } catch (e) {
      // Gestionează alte tipuri de erori
      setState(() => error = 'Eroare la crearea contului: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      // Bara de sus cu titlul
      appBar: AppBar(
        title: const Text('Înregistrare'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleTextStyle: const TextStyle(
            color: Colors.deepPurple, fontSize: 22, fontWeight: FontWeight.bold),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                // Formular de înregistrare
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icoană pentru adăugare utilizator
                    const Icon(Icons.person_add,
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
                    // Buton creare cont
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text("Creează cont"),
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
                    // Afișare mesaj de eroare
                    if (error.isNotEmpty)
                      Text(error, style: const TextStyle(color: Colors.red)),
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
