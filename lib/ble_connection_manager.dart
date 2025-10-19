// Import necesar pentru funcționalitatea Bluetooth Low Energy
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Manager pentru conexiunea Bluetooth Low Energy
/// Implementat ca Singleton pentru a asigura o singură instanță în aplicație
class BleConnectionManager {
  // Instanța singleton
  static final BleConnectionManager _instance = BleConnectionManager._internal();
  
  // Constructor factory care returnează instanța singleton
  factory BleConnectionManager() => _instance;
  
  // Constructor privat pentru singleton
  BleConnectionManager._internal();

  // Dispozitivul BLE conectat curent
  BluetoothDevice? connectedDevice;
  
  // Caracteristica BLE pentru citirea pulsului
  BluetoothCharacteristic? heartRateChar;

  /// Resetează conexiunea BLE
  /// Șterge referințele către dispozitiv și caracteristică
  void clear() {
    connectedDevice = null;
    heartRateChar = null;
  }
}
