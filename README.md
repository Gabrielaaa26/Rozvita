# RozVita - Aplicație de Monitorizare Puls

O aplicație Flutter pentru monitorizarea pulsului prin conectivitate Bluetooth Low Energy (BLE) cu ESP32.

## Funcționalități

### 🔐 Autentificare
- Înregistrare și autentificare cu Firebase Auth
- Resetare parolă prin email
- Gestionare automată a sesiunilor

### 👤 Profil Utilizator
- Editare profil (nume, vârstă, înălțime, greutate)
- Încărcare poză de profil
- Sincronizare automată cu Firestore

### 📊 Monitorizare Puls
- Conectare BLE cu dispozitive ESP32
- Citire puls în timp real
- Grafic evoluție puls (ultimele 30 măsurători)
- Salvare automată în Firebase Firestore

### 📈 Istoric
- Vizualizare istoric măsurători
- Grafice interactive cu fl_chart
- Filtrare pe perioada dorită

## Tehnologii Utilizate

- **Flutter** - Framework mobile
- **Firebase Auth** - Autentificare
- **Cloud Firestore** - Baza de date
- **Firebase Storage** - Stocare imagini
- **Flutter Blue Plus** - Conectivitate BLE
- **FL Chart** - Grafice interactive

## Instalare

1. Clonați repository-ul:
```bash
git clone https://github.com/[username]/rozvita.git
cd rozvita
```

2. Instalați dependințele:
```bash
flutter pub get
```

3. Configurați Firebase:
   - Creați un proiect Firebase
   - Adăugați aplicația Flutter
   - Descărcați `google-services.json` în `android/app/`
   - Configurați `firebase_options.dart`

4. Rulați aplicația:
```bash
flutter run
```

## Configurare Firebase

### Firestore Collections

#### users
```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "age": "number",
  "height": "number",
  "weight": "number",
  "profileImage": "string",
  "createdAt": "timestamp"
}
```

#### pulsuri
```json
{
  "uid": "string",
  "bpm": "number",
  "timestamp": "timestamp"
}
```

## Licență

Acest proiect este sub licența MIT.
