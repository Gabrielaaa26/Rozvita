import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _isEditMode = false;
  String? _profileImageUrl;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data()!;
            _profileImageUrl = _userData?['profileImage'];
            _nameController.text = _userData?['name'] ?? '';
            _ageController.text = _userData?['age']?.toString() ?? '';
            _heightController.text = _userData?['height']?.toString() ?? '';
            _weightController.text = _userData?['weight']?.toString() ?? '';
          });
        } else {
          // Creează documentul dacă nu există (pentru utilizatori vechi)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email ?? '',
            'createdAt': Timestamp.now(),
            'name': '',
            'age': 0,
            'height': 0,
            'weight': 0,
            'profileImage': null,
          });
          
          // Încarcă din nou datele
          await _loadUserData();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    final status = await Permission.photos.request();
    
    if (status.isGranted) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        
        if (image != null) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Afișează dialog de progres
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text('Se încarcă imaginea...'),
                  ],
                ),
              ),
            );
            
            final ref = FirebaseStorage.instance
                .ref()
                .child('profile_images')
                .child('${user.uid}.jpg');
            
            await ref.putFile(File(image.path));
            final url = await ref.getDownloadURL();
            
            // Actualizează documentul în Firestore (sau creează-l dacă nu există)
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'profileImage': url,
            }, SetOptions(merge: true));
            
            setState(() {
              _profileImageUrl = url;
            });
            
            // Închide dialogul de progres
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Imaginea a fost încărcată cu succes!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } catch (e) {
        // Închide dialogul de progres dacă este deschis
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la încărcarea imaginii: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să acordați acces la galerie')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Folosește set cu merge pentru a crea documentul dacă nu există
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
        }, SetOptions(merge: true));
        
        setState(() {
          _isEditMode = false;
          _loadUserData(); // Reload the data to show updated values
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilul a fost actualizat cu succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la salvarea profilului: $e')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFFB993D6),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      resizeToAvoidBottomInset: true, // Permite redimensionarea când apare tastatura
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFFB993D6),
      ),
      body: SafeArea(
        child: _isEditMode ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: _uploadImage,
                    child: Hero(
                      tag: 'profileImage',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFB993D6),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? Icon(Icons.person,
                                  size: 60,
                                  color: Colors.deepPurple.shade200)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _userData?['name'] ?? 'Adaugă numele tău',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB993D6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB993D6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB993D6).withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildDetailRow(
                            'Vârstă:', '${_userData?['age'] ?? 'N/A'} ani'),
                        Divider(height: 16, color: const Color(0xFFB993D6).withOpacity(0.2)),
                        _buildDetailRow('Înălțime:',
                            '${_userData?['height'] ?? 'N/A'} cm'),
                        Divider(height: 16, color: const Color(0xFFB993D6).withOpacity(0.2)),
                        _buildDetailRow('Greutate:',
                            '${_userData?['weight'] ?? 'N/A'} kg'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditMode = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB993D6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editează Profilul',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFB993D6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _isEditMode = false),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Editează Profilul',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance pentru IconButton
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16, 
                16, 
                16, 
                MediaQuery.of(context).viewInsets.bottom + 16
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nume',
                      labelStyle: const TextStyle(color: Color(0xFFB993D6)),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFB993D6)),
                      filled: true,
                      fillColor: const Color(0xFFB993D6).withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFB993D6).withOpacity(0.3)
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFB993D6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Vârstă',
                      labelStyle: const TextStyle(color: Color(0xFFB993D6)),
                      prefixIcon: const Icon(Icons.cake, color: Color(0xFFB993D6)),
                      filled: true,
                      fillColor: const Color(0xFFB993D6).withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFB993D6).withOpacity(0.3)
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFB993D6)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: 'Înălțime (cm)',
                      labelStyle: const TextStyle(color: Color(0xFFB993D6)),
                      prefixIcon: const Icon(Icons.height, color: Color(0xFFB993D6)),
                      filled: true,
                      fillColor: const Color(0xFFB993D6).withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFB993D6).withOpacity(0.3)
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFB993D6)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Greutate (kg)',
                      labelStyle: const TextStyle(color: Color(0xFFB993D6)),
                      prefixIcon: const Icon(
                        Icons.monitor_weight,
                        color: Color(0xFFB993D6)
                      ),
                      filled: true,
                      fillColor: const Color(0xFFB993D6).withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFB993D6).withOpacity(0.3)
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFB993D6)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _isEditMode = false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: const Color(0xFFB993D6).withOpacity(0.5)
                            ),
                          ),
                          child: const Text(
                            'Anulează',
                            style: TextStyle(
                              color: Color(0xFFB993D6),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB993D6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Salvează',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
