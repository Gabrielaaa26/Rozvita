# Documentație Tehnică - ROZvita Health

## Descriere Generală
ROZvita Health este o aplicație mobilă dezvoltată în Flutter pentru monitorizarea pulsului prin intermediul unei brățări inteligente. Aplicația folosește tehnologia Bluetooth Low Energy (BLE) pentru comunicarea cu brățara și oferă funcționalități de autentificare, stocare și vizualizare a datelor.

## Tehnologii Utilizate
- **Framework**: Flutter
- **Limbaj**: Dart
- **Backend**: Firebase (Authentication, Firestore)
- **Comunicare Hardware**: Bluetooth Low Energy (BLE)
- **Stocare Date**: Cloud Firestore
- **Autentificare**: Firebase Authentication
- **Vizualizare Date**: fl_chart

## Arhitectura Aplicației

### 1. Structura Proiectului
```
lib/
├── auth/                  # Componente pentru autentificare
│   ├── login_screen.dart
│   └── register_screen.dart
├── screens/              # Ecranele principale ale aplicației
│   ├── home_menu_screen.dart
│   ├── scan_screen.dart
│   ├── pulse_screen.dart
│   ├── history_screen.dart
│   └── profile_screen.dart
├── ble_connection_manager.dart  # Manager pentru conexiunea BLE
├── firebase_options.dart        # Configurări Firebase
└── main.dart                    # Punctul de intrare în aplicație
```

### 2. Componente Principale

#### 2.1 Sistem de Autentificare
- Implementat folosind Firebase Authentication
- Funcționalități:
  - Înregistrare utilizator nou (email/parolă)
  - Autentificare utilizator existent
  - Resetare parolă
  - Păstrarea stării de autentificare
- Fișiere relevante:
  - `auth/login_screen.dart`
  - `auth/register_screen.dart`

#### 2.2 Conexiune Bluetooth (BLE)
- Manager dedicat pentru conexiunea BLE (`ble_connection_manager.dart`)
- Funcționalități:
  - Scanare dispozitive BLE
  - Conectare la brățară
  - Citire caracteristică de puls (UUID: 0x2A37)
  - Gestionare deconectare
- Pattern Singleton pentru gestionarea unei singure conexiuni
- Permisiuni Android/iOS pentru BLE

#### 2.3 Procesare și Stocare Date
- Stocare în Cloud Firestore
- Colecții:
  - `users`: Informații utilizatori
  - `pulsuri`: Măsurători puls
- Structură date pentru măsurători:
```json
{
  "uid": "string",      // ID-ul utilizatorului
  "bpm": number,        // Valoarea pulsului
  "timestamp": timestamp // Momentul măsurătorii
}
```

#### 2.4 Interfața cu Utilizatorul
- Implementare Material Design
- Teme și culori personalizate
- Ecrane principale:
  1. **Meniu Principal** (`home_menu_screen.dart`)
     - Dashboard cu carduri pentru funcții
     - Profil utilizator
     - Navigare către toate funcționalitățile

  2. **Scanare BLE** (`scan_screen.dart`)
     - Interfață pentru scanare dispozitive
     - Lista dispozitivelor găsite
     - Gestionare conexiune

  3. **Măsurare Puls** (`pulse_screen.dart`)
     - Afișare puls în timp real
     - Grafic pentru ultimele măsurători
     - Salvare automată în Firestore

  4. **Istoric** (`history_screen.dart`)
     - Vizualizare măsurători salvate
     - Grafic interactiv
     - Funcție de ștergere istoric

### 3. Fluxuri de Date

#### 3.1 Flux Măsurare Puls
1. Scanare și conectare la brățară
2. Citire caracteristică BLE (0x2A37)
3. Procesare date primite
4. Afișare în timp real
5. Salvare în Firestore

#### 3.2 Flux Autentificare
1. Utilizator introduce credențiale
2. Validare prin Firebase Auth
3. Creare/actualizare sesiune
4. Redirecționare către meniul principal

### 4. Securitate
- Autentificare securizată prin Firebase
- Reguli Firestore pentru acces date
- Validare date de intrare
- Gestionare erori și excepții
- Protecție împotriva accesului neautorizat

### 5. Optimizări
- Singleton pattern pentru BLE
- Caching date pentru performanță
- Lazy loading pentru liste lungi
- Gestionare eficientă a resurselor
- Validări locale înainte de cereri la server

### 6. Cerințe Sistem
- Android 6.0 (API 23) sau mai nou
- iOS 11.0 sau mai nou
- Bluetooth 4.0 LE sau mai nou
- Servicii Google Play (Android)

### 7. Dependențe Principale
```yaml
dependencies:
  flutter_blue_plus: ^1.x.x    # Comunicare BLE
  firebase_core: ^2.x.x        # Core Firebase
  firebase_auth: ^4.x.x        # Autentificare
  cloud_firestore: ^4.x.x      # Bază de date
  fl_chart: ^0.x.x            # Grafice
  permission_handler: ^10.x.x  # Gestionare permisiuni
```

## Implementare Funcționalități Cheie

### 1. Conectare BLE
```dart
// Exemplu de cod pentru conectare BLE
Future<void> connectToDevice(BluetoothDevice device) async {
  await device.connect(autoConnect: false);
  List<BluetoothService> services = await device.discoverServices();
  
  for (var service in services) {
    for (var characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toUpperCase().contains("2A37")) {
        // Caracteristica de puls găsită
        await characteristic.setNotifyValue(true);
        // Procesare date...
      }
    }
  }
}
```

### 2. Procesare Date Puls
```dart
// Exemplu de cod pentru procesare date puls
void processPulseData(List<int> data) {
  if (data.isNotEmpty) {
    int pulse;
    if ((data[0] & 0x01) != 0 && data.length > 2) {
      pulse = data[1] | (data[2] << 8);
    } else {
      pulse = data[1];
    }
    
    if (pulse > 0 && pulse < 220) {
      // Salvare și afișare...
    }
  }
}
```

### 3. Salvare Date în Firestore
```dart
// Exemplu de cod pentru salvare date
Future<void> savePulseData(int pulse) async {
  await FirebaseFirestore.instance.collection('pulsuri').add({
    'uid': FirebaseAuth.instance.currentUser?.uid,
    'bpm': pulse,
    'timestamp': Timestamp.now(),
  });
}
```

## Implementare Detaliată a Interfețelor

### 1. Sistem de Autentificare și Înregistrare

#### 1.1 Ecranul de Autentificare (`login_screen.dart`)
- **Design și Layout**:
  - Gradient de fundal: `LinearGradient` de la `Color(0xFFB993D6)` la `Color(0xFF8CA6DB)`
  - Card central cu elevație și colțuri rotunjite (radius: 32)
  - Iconița de lacăt animată în partea superioară
  - Câmpuri de input cu validare:
    - Email (TextInputType.emailAddress)
    - Parolă (obscureText: true)
  - Butoane:
    - "Autentificare" (ElevatedButton cu icon)
    - "Am uitat parola" (TextButton)
    - "Nu ai cont? Creează unul!" (TextButton)

```dart
// Exemplu implementare validare email
bool isValidEmail(String email) {
  return email.contains('@') && 
         email.contains('.') && 
         email.length >= 5;
}

// Exemplu implementare autentificare
Future<void> login() async {
  if (!isValidEmail(emailController.text)) {
    setState(() => error = 'Email invalid');
    return;
  }
  
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  } on FirebaseAuthException catch (e) {
    // Gestionare erori specifice...
  }
}
```

#### 1.2 Ecranul de Înregistrare (`register_screen.dart`)
- **Design și Layout**:
  - Aceeași temă vizuală ca ecranul de login
  - Iconiță specifică (person_add)
  - Validări suplimentare:
    - Email unic
    - Parolă minimă 6 caractere
    - Confirmare parolă
  - Înregistrare automată în Firestore

```dart
// Exemplu implementare înregistrare
Future<void> register() async {
  if (password != confirmPassword) {
    setState(() => error = 'Parolele nu coincid');
    return;
  }
  
  try {
    UserCredential userCredential = 
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
    // Creare document utilizator în Firestore
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userCredential.user!.uid)
      .set({
        'email': email,
        'createdAt': Timestamp.now(),
        // ... alte câmpuri
      });
  } catch (e) {
    // Gestionare erori...
  }
}
```

#### 1.3 Funcționalitatea "Resetare Parolă"
- **Implementare**:
  - Validare email înainte de trimitere
  - Utilizare Firebase Auth pentru trimitere email
  - Dialog de confirmare cu instrucțiuni
  - Gestionare erori specifice

```dart
// Exemplu implementare resetare parolă
Future<void> resetPassword() async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim()
    );
    
    // Afișare dialog confirmare
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email trimis'),
        content: Text('Verificați căsuța de email pentru instrucțiuni'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } on FirebaseAuthException catch (e) {
    // Gestionare erori specifice...
  }
}
```

### 2. Implementare Grafice și Vizualizare Date

#### 2.1 Graficul de Puls în Timp Real (`pulse_screen.dart`)
- **Caracteristici**:
  - Actualizare în timp real
  - Animații fluide
  - Scală dinamică
  - Indicator valoare curentă
  - Cod culori pentru valori normale/anormale

```dart
// Exemplu configurare grafic timp real
LineChartData getRealtimeChartData() {
  return LineChartData(
    minY: 40,  // Puls minim normal
    maxY: 180, // Puls maxim normal
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(show: false),
    borderData: FlBorderData(show: false),
    lineBarsData: [
      LineChartBarData(
        spots: bpmHistory
            .asMap()
            .entries
            .map((e) => FlSpot(
                  e.key.toDouble(),
                  e.value.toDouble(),
                ))
            .toList(),
        isCurved: true,
        color: Colors.deepPurple,
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) {
            return FlDotCirclePainter(
              radius: 2.5,
              strokeWidth: 1.5,
              color: Colors.deepPurple,
            );
          },
        ),
      ),
    ],
  );
}
```

#### 2.2 Graficul de Istoric (`history_screen.dart`)
- **Funcționalități**:
  - Filtrare măsurători (eliminare valori 0)
  - Limitare la ultimele 30 de măsurători
  - Scalare automată axă Y
  - Interactivitate (zoom, pan)
  - Export date

```dart
// Exemplu procesare date pentru grafic istoric
List<FlSpot> processHistoryData(List<Map<String, dynamic>> data) {
  // Filtrare și sortare date
  final validData = data
    .where((m) => m['pulse'] > 0)
    .toList()
    ..sort((a, b) => (a['timestamp'] as Timestamp)
        .compareTo(b['timestamp'] as Timestamp));

  // Limitare la ultimele 30 de măsurători
  final recentData = validData.length > 30 
    ? validData.sublist(validData.length - 30) 
    : validData;

  // Conversie în puncte pentru grafic
  return recentData
    .asMap()
    .entries
    .map((e) => FlSpot(
          e.key.toDouble(),
          e.value['pulse'].toDouble(),
        ))
    .toList();
}
```

#### 2.3 Interfața de Vizualizare a Datelor
- **Componente**:
  - Card grafic principal
  - Listă măsurători cu timestamp
  - Statistici rapide (min, max, medie)
  - Buton ștergere istoric
  - Indicator status măsurare

```dart
// Exemplu calcul statistici
Map<String, double> calculateStats(List<Map<String, dynamic>> data) {
  if (data.isEmpty) return {
    'min': 0,
    'max': 0,
    'avg': 0,
  };

  var validPulses = data
    .map((m) => m['pulse'] as num)
    .where((p) => p > 0)
    .toList();

  return {
    'min': validPulses.reduce(min).toDouble(),
    'max': validPulses.reduce(max).toDouble(),
    'avg': validPulses.reduce((a, b) => a + b) / validPulses.length,
  };
}
```

### 3. Gestionare Stare și Context

#### 3.1 Managementul Stării de Autentificare
- Utilizare `StreamBuilder` pentru monitorizare autentificare
- Păstrare stare între reporniri aplicație
- Gestionare token-uri de autentificare
- Actualizare UI bazată pe stare

```dart
// Exemplu implementare AuthGate
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }
        if (snapshot.hasData) {
          return HomeMenuScreen();
        }
        return LoginScreen();
      },
    );
  }
}
```

#### 3.2 Managementul Datelor
- Cache local pentru performanță
- Sincronizare în fundal cu Firestore
- Gestionare erori de rețea
- Validare date înainte de salvare

```dart
// Exemplu implementare cache date
class PulseDataCache {
  static final List<Map<String, dynamic>> _cache = [];
  static bool _needsSync = false;

  static Future<void> addMeasurement(Map<String, dynamic> data) async {
    _cache.add(data);
    _needsSync = true;
    
    // Sincronizare automată când există conexiune
    if (await hasInternetConnection()) {
      await syncWithFirestore();
    }
  }

  static Future<void> syncWithFirestore() async {
    if (!_needsSync) return;
    
    try {
      // Sincronizare cu Firestore
      for (var data in _cache) {
        await FirebaseFirestore.instance
          .collection('pulsuri')
          .add(data);
      }
      
      _cache.clear();
      _needsSync = false;
    } catch (e) {
      // Gestionare erori...
    }
  }
}
```

### 4. Optimizări și Best Practices

#### 4.1 Optimizări de Performanță
- Lazy loading pentru liste lungi
- Caching date frecvent accesate
- Compresie imagini profil
- Debouncing pentru input-uri
- Batching pentru operații Firestore

```dart
// Exemplu implementare debouncing
Timer? _debounce;

void onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    // Execută căutarea
    searchUsers(query);
  });
}
```

#### 4.2 Gestionare Memorie
- Eliberare resurse nefolosite
- Închidere stream-uri și subscriptions
- Curățare cache periodic
- Monitorizare memory leaks

```dart
// Exemplu gestionare resurse
@override
void dispose() {
  _pulseSubscription?.cancel();
  _authStateSubscription?.cancel();
  _debounce?.cancel();
  _animationController.dispose();
  super.dispose();
}
```

#### 4.3 Securitate
- Validare input-uri utilizator
- Sanitizare date înainte de salvare
- Rate limiting pentru operații critice
- Logging pentru acțiuni importante

```dart
// Exemplu validare și sanitizare input
String sanitizeInput(String input) {
  return input
    .trim()
    .replaceAll(RegExp(r'[^\w\s@.-]'), '')
    .toLowerCase();
}

// Exemplu rate limiting
class RateLimiter {
  static final Map<String, DateTime> _lastAttempts = {};
  static const _minInterval = Duration(seconds: 3);

  static bool checkRateLimit(String operation) {
    final now = DateTime.now();
    final lastAttempt = _lastAttempts[operation];
    
    if (lastAttempt != null &&
        now.difference(lastAttempt) < _minInterval) {
      return false;
    }
    
    _lastAttempts[operation] = now;
    return true;
  }
}
```

## Diagrame UML

### 1. Diagrama Use Case

#### 1.1 Actori
1. **Utilizator**
   - Utilizatorul principal al aplicației
   - Poate fi autentificat sau neautentificat
   - Interacționează cu toate funcționalitățile aplicației

2. **Brățară BLE**
   - Dispozitiv extern Bluetooth Low Energy
   - Furnizează date despre puls
   - Comunică cu aplicația prin protocol BLE

#### 1.2 Cazuri de Utilizare

##### Autentificare
1. **Înregistrare cont**
   - Creare cont nou cu email și parolă
   - Validare date introduse
   - Creare profil în Firestore

2. **Autentificare**
   - Login cu email și parolă
   - Gestionare sesiune
   - Redirecționare către meniul principal

3. **Resetare parolă**
   - Solicitare resetare prin email
   - Validare adresă email
   - Trimitere instrucțiuni de resetare

4. **Deconectare**
   - Închidere sesiune curentă
   - Ștergere date locale
   - Redirecționare către login

##### Gestionare Profil
5. **Vizualizare profil**
   - Afișare informații utilizator
   - Afișare poză profil
   - Afișare statistici generale

6. **Editare profil**
   - Modificare informații personale
   - Validare date noi
   - Salvare în Firestore

7. **Încărcare poză profil**
   - Selectare imagine din galerie
   - Upload în Firebase Storage
   - Actualizare URL în profil

##### Conexiune Brățară
8. **Scanare dispozitive BLE**
   - Căutare dispozitive în apropiere
   - Filtrare după servicii suportate
   - Afișare listă dispozitive găsite

9. **Conectare la brățară**
   - Stabilire conexiune BLE
   - Descoperire servicii și caracteristici
   - Activare notificări pentru puls

10. **Deconectare brățară**
    - Închidere conexiune BLE
    - Curățare resurse
    - Reset stare conexiune

##### Monitorizare Puls
11. **Vizualizare puls în timp real**
    - Citire date de la brățară
    - Procesare și validare valori
    - Afișare cu animații

12. **Salvare măsurători**
    - Stocare automată în Firestore
    - Validare date înainte de salvare
    - Gestionare erori

13. **Vizualizare grafic timp real**
    - Afișare grafic interactiv
    - Actualizare în timp real
    - Indicatori vizuali pentru valori

##### Istoric
14. **Vizualizare istoric măsurători**
    - Afișare listă măsurători
    - Paginare rezultate
    - Ordonare după timestamp

15. **Filtrare măsurători**
    - Filtrare după dată
    - Filtrare după valori
    - Eliminare măsurători invalide

16. **Ștergere istoric**
    - Ștergere selectivă sau completă
    - Confirmare acțiune
    - Actualizare UI

17. **Vizualizare statistici**
    - Calcul valori min/max/medie
    - Generare grafice statistice
    - Afișare tendințe

#### 1.3 Relații și Dependențe

1. **Incluziuni**
   - Autentificarea include vizualizarea profilului
   - Conectarea la brățară include monitorizarea pulsului
   - Vizualizarea pulsului include salvarea și afișarea graficului
   - Vizualizarea istoricului include statisticile

2. **Fluxuri de Date**
   - Brățara → Aplicație: date puls
   - Aplicație → Firebase: salvare date
   - Firebase → Aplicație: încărcare istoric

3. **Precondiții**
   - Autentificare necesară pentru majoritatea funcțiilor
   - Conexiune BLE necesară pentru monitorizare
   - Conexiune internet pentru sincronizare

#### 1.4 Notițe Implementare

1. **Securitate**
   - Validare date la toate intrările
   - Verificare permisiuni pentru fiecare acțiune
   - Gestionare token-uri autentificare

2. **Performanță**
   - Widgeturile sunt extensibile
   - Comportament personalizabil prin proprietăți

3. **Experiență Utilizator**
   - Feedback vizual pentru acțiuni
   - Indicatori de loading
   - Mesaje de eroare clare
   - Confirmări pentru acțiuni importante

### 2. Diagrama de Clase

#### 2.1 Pachete Principale

##### 2.1.1 Pachetul "Auth"
1. **LoginScreen**
   - Gestionează autentificarea utilizatorilor
   - Implementează resetarea parolei
   - Gestionează starea de încărcare și erori
   - Atribute principale:
     - `emailController`: Controller pentru input email
     - `passwordController`: Controller pentru input parolă
     - `isLoading`: Indicator stare încărcare
     - `error`: Mesaj de eroare
   - Metode principale:
     - `login()`: Procesează autentificarea
     - `resetPassword()`: Gestionează resetarea parolei

2. **RegisterScreen**
   - Gestionează înregistrarea utilizatorilor noi
   - Validează datele de înregistrare
   - Atribute și metode similare cu LoginScreen

##### 2.1.2 Pachetul "Core"
1. **BleConnectionManager**
   - Implementează pattern-ul Singleton
   - Gestionează conexiunea BLE
   - Atribute principale:
     - `connectedDevice`: Dispozitivul conectat
     - `heartRateChar`: Caracteristica pentru puls
   - Metode principale:
     - `getInstance()`: Returnează instanța singleton
     - `clear()`: Resetează conexiunea

2. **User**
   - Model pentru datele utilizatorului
   - Atribute principale:
     - `uid`: ID unic utilizator
     - `email`: Adresa email
     - `name`: Nume utilizator
     - `profileImageUrl`: URL poză profil
   - Metode:
     - `toMap()`: Convertește în Map pentru Firestore
     - `fromMap()`: Creează obiect din date Firestore

3. **PulseMeasurement**
   - Model pentru măsurătorile de puls
   - Atribute principale:
     - `id`: ID unic măsurătoare
     - `uid`: ID utilizator
     - `bpm`: Valoare puls
     - `timestamp`: Momentul măsurătorii

##### 2.1.3 Pachetul "Screens"
1. **HomeMenuScreen**
   - Ecranul principal al aplicației
   - Gestionează navigarea către alte ecrane
   - Afișează informații utilizator
   - Metode principale pentru navigare și logout

2. **ScanScreen**
   - Gestionează scanarea dispozitivelor BLE
   - Afișează lista dispozitivelor găsite
   - Gestionează conectarea la dispozitive

3. **PulseScreen**
   - Afișează pulsul în timp real
   - Gestionează istoricul măsurătorilor
   - Implementează graficul în timp real

4. **HistoryScreen**
   - Afișează istoricul măsurătorilor
   - Implementează filtrare și ștergere
   - Gestionează graficul istoric

5. **ProfileScreen**
   - Gestionează profilul utilizatorului
   - Implementează editare și upload poză

##### 2.1.4 Pachetul "Widgets"
1. **MenuCard**
   - Widget reutilizabil pentru meniul principal
   - Personalizabil prin proprietăți

2. **PulseChart**
   - Widget pentru afișarea graficelor
   - Utilizat atât în PulseScreen cât și HistoryScreen

3. **ProfileImage**
   - Widget pentru afișarea și gestionarea pozei de profil

#### 2.2 Relații între Clase

1. **Relații de Compunere**
   - BleConnectionManager → HomeMenuScreen
   - BleConnectionManager → ScanScreen
   - BleConnectionManager → PulseScreen
   - PulseScreen → PulseChart
   - ProfileScreen → ProfileImage

2. **Relații de Agregare**
   - HomeMenuScreen → MenuCard (4 instanțe)
   - HistoryScreen → PulseChart

3. **Relații de Dependență**
   - LoginScreen → User (creare)
   - RegisterScreen → User (creare)
   - PulseScreen → PulseMeasurement (creare)

4. **Relații de Navigare**
   - HomeMenuScreen → toate celelalte ecrane principale

#### 2.3 Pattern-uri de Design Utilizate

1. **Singleton**
   - Implementat în BleConnectionManager
   - Asigură o singură instanță pentru conexiunea BLE

2. **Factory Method**
   - Utilizat în modelele User și PulseMeasurement
   - Metode statice fromMap pentru crearea obiectelor

3. **Observer**
   - Utilizat pentru actualizări în timp real
   - Implementat prin StreamBuilder și setState

4. **State**
   - Gestionarea stării aplicației prin StatefulWidget
   - Separare între logică și UI

#### 2.4 Principii SOLID Aplicate

1. **Single Responsibility**
   - Fiecare clasă are o singură responsabilitate
   - Separare clară între UI, logică și date

2. **Open/Closed**
   - Widgeturile sunt extensibile
   - Comportament personalizabil prin proprietăți

3. **Interface Segregation**
   - Widgeturile expun doar metodele necesare
   - Interfețe clare pentru callback-uri

4. **Dependency Inversion**
   - Dependențe injectate prin constructori
   - Utilizare de clase abstracte unde este necesar

#### 2.5 Cardinalitatea Relațiilor

##### 2.5.1 Relații One-to-Many (1:N)
1. **User - PulseMeasurement**
   - Un utilizator (1) poate avea multiple (N) măsurători de puls
   - Relație implementată prin câmpul `uid` în PulseMeasurement
   - Metodă `getMeasurements()` în User pentru a obține toate măsurătorile

2. **HomeMenuScreen - MenuCard**
   - Un ecran principal (1) conține exact patru (4) carduri de meniu
   - Relație de compunere strictă
   - Cardurile sunt create și gestionate de HomeMenuScreen

##### 2.5.2 Relații One-to-One (1:1)
1. **User - ProfileScreen**
   - Un utilizator (1) are un singur (1) ecran de profil
   - Datele utilizatorului sunt afișate și editate în ProfileScreen
   - Relație bidirecțională prin referencias și actualizări

2. **BleConnectionManager - BluetoothDevice**
   - Managerul BLE (1) poate fi conectat la un singur (0..1) dispozitiv
   - Relație opțională (poate fi null când nu există conexiune)
   - Gestionată prin Singleton pattern

##### 2.5.3 Relații Many-to-One (N:1)
1. **PulseMeasurement - User**
   - Multiple măsurători (N) aparțin unui singur (1) utilizator
   - Referință prin câmpul `uid` în PulseMeasurement
   - Metodă `getUser()` în PulseMeasurement pentru a obține utilizatorul asociat

##### 2.5.4 Relații de Asociere
1. **HomeMenuScreen - Alte Ecrane**
   - Navigare one-way către alte ecrane
   - Relație de tip (1) la (0..1) - un ecran poate fi deschis sau nu
   - Implementată prin NavigatorState

2. **BleConnectionManager - Ecrane**
   - Singleton manager folosit în multiple ecrane
   - Relație de tip (1) la (0..1) pentru fiecare ecran
   - Acces prin getInstance()

##### 2.5.5 Restricții și Validări
1. **Integritate Referențială**
   - Ștergerea unui User implică ștergerea tuturor PulseMeasurements asociate
   - Validare `uid` la crearea măsurătorilor
   - Verificare existență utilizator pentru operații

2. **Constrângeri de Business**
   - O măsurătoare trebuie să aibă un utilizator valid
   - Un utilizator trebuie să aibă email unic
   - Valorile pulsului trebuie să fie în interval valid (40-220)

##### 2.5.6 Implementare în Cod

```dart
// Exemplu implementare relație One-to-Many
class User {
  final String uid;
  // ... alte câmpuri

  Future<List<PulseMeasurement>> getMeasurements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pulsuri')
        .where('uid', isEqualTo: uid)
        .get();
    
    return snapshot.docs
        .map((doc) => PulseMeasurement.fromMap(doc.data()))
        .toList();
  }
}

// Exemplu implementare relație Many-to-One
class PulseMeasurement {
  final String uid;
  // ... alte câmpuri

  Future<User?> getUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    if (doc.exists) {
      return User.fromMap(doc.data()!);
    }
    return null;
  }
}

// Exemplu implementare relație One-to-One
class BleConnectionManager {
  BluetoothDevice? connectedDevice;
  
  Future<void> connect(BluetoothDevice device) async {
    if (connectedDevice != null) {
      await disconnect();
    }
    await device.connect();
    connectedDevice = device;
  }
  
  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
  }
}
```

## Relații între Clase și Cardinalitate

### 1. Relații Core

#### User - PulseMeasurement (1:N)
- Un utilizator (`User`) poate avea multiple măsurători de puls (`PulseMeasurement`)
- O măsurătoare de puls aparține unui singur utilizator
- Implementare:
```dart
// În clasa User
Future<List<PulseMeasurement>> getMeasurements() async {
    final measurements = await FirebaseFirestore.instance
        .collection('pulsuri')
        .where('uid', isEqualTo: this.uid)
        .get();
    return measurements.docs
        .map((doc) => PulseMeasurement.fromMap(doc.data()))
        .toList();
}

// În clasa PulseMeasurement
Future<User> getUser() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(this.uid)
        .get();
    return User.fromMap(userDoc.data()!);
}
```

#### BleConnectionManager - BluetoothDevice (1:0..1)
- Managerul BLE (`BleConnectionManager`) poate fi conectat la maximum un dispozitiv (`BluetoothDevice`) la un moment dat
- Pattern Singleton pentru a asigura o singură instanță a managerului
- Implementare:
```dart
class BleConnectionManager {
    static BleConnectionManager? _instance;
    BluetoothDevice? connectedDevice;

    static BleConnectionManager getInstance() {
        _instance ??= BleConnectionManager();
        return _instance!;
    }
}
```

### 2. Relații UI

#### HomeMenuScreen - MenuCard (1:4)
- Ecranul principal (`HomeMenuScreen`) conține exact 4 carduri de meniu (`MenuCard`)
- Relație de compoziție (cardurile nu există independent de ecran)
- Carduri pentru: Scanare, Măsurare, Istoric, Profil

#### PulseScreen/HistoryScreen - PulseChart (1:1)
- Atât `PulseScreen` cât și `HistoryScreen` conțin exact un grafic (`PulseChart`)
- Graficele sunt configurate diferit pentru fiecare ecran:
  - PulseScreen: timp real, actualizare continuă
  - HistoryScreen: istoric, interactiv, zoom permis

#### ProfileScreen - ProfileImage (1:1)
- Ecranul de profil (`ProfileScreen`) conține exact o imagine de profil (`ProfileImage`)
- Imaginea poate fi actualizată prin interfața de utilizator

### 3. Relații de Autentificare

#### User - LoginScreen/RegisterScreen (1:1)
- Un utilizator este autentificat printr-un singur ecran de login
- Un utilizator este înregistrat printr-un singur ecran de înregistrare
- Implementare bazată pe Firebase Authentication

### 4. Relații de Navigare

#### HomeMenuScreen - Alte Ecrane (1:0..1)
- Navigare unidirecțională de la meniul principal către celelalte ecrane
- Un singur ecran poate fi activ la un moment dat
- Implementare prin Navigator 2.0:
```dart
void _goToScreen(BuildContext context, Widget screen) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen)
    );
}
```

### 5. Relații cu Baza de Date

#### PulseMeasurement - HistoryScreen (N:1)
- Multiple măsurători sunt afișate în ecranul de istoric
- Datele sunt filtrate și ordonate pentru afișare
- Implementare prin Firestore Queries

#### User - ProfileScreen (1:1)
- Datele unui utilizator sunt afișate și editate în ecranul de profil
- Sincronizare bidirecțională cu Firestore
```
