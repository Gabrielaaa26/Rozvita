// Importuri necesare pentru scanarea și conectarea BLE
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'pulse_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ble_connection_manager.dart';

/// Ecranul de scanare pentru dispozitive BLE
/// Permite căutarea și conectarea la brățara inteligentă
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

/// Starea ecranului de scanare
class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> discoveredDevices = []; // Lista dispozitivelor găsite
  bool isScanning = false;                      // Indicator pentru scanare activă
  String status = "🔎 Caută brățara...";       // Mesaj de status curent

  @override
  void initState() {
    super.initState();
    _initBluetooth(); // Inițializează Bluetooth la pornirea ecranului
  }

  /// Inițializează Bluetooth și cere permisiunile necesare
  Future<void> _initBluetooth() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
    startScan();
  }

  /// Începe scanarea pentru dispozitive BLE
  void startScan() async {
    setState(() {
      isScanning = true;
      discoveredDevices.clear();
      status = "🔍 Se scanează...";
    });

    // Ascultă rezultatele scanării
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        final name = r.device.platformName;
        // Filtrează dispozitivele după nume sau servicii
        if (!discoveredDevices.contains(r.device) &&
            (name.contains("RozVita") || r.advertisementData.serviceUuids.contains("180D"))) {
          setState(() => discoveredDevices.add(r.device));
        }
      }
    });

    // Scanează pentru 15 secunde
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    setState(() => isScanning = false);
  }

  /// Conectează la un dispozitiv BLE și caută serviciul de puls
  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() => status = "🔌 Se conectează la ${device.platformName}...");
    await FlutterBluePlus.stopScan();

    try {
      // Conectare la dispozitiv
      await device.connect(autoConnect: false);
      List<BluetoothService> services = await device.discoverServices();
      
      // Caută caracteristica de puls (2A37)
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.uuid.toString().toUpperCase().contains("2A37")) {
            // Salvează conexiunea în managerul global
            BleConnectionManager().connectedDevice = device;
            BleConnectionManager().heartRateChar = c;
            
            // Navighează la ecranul de puls
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PulseScreen(
                  connectedDevice: device,
                  heartRateChar: c,
                ),
              ),
            );
            return;
          }
        }
      }

      setState(() => status = "❌ Caracteristica 2A37 nu a fost găsită.");
    } catch (e) {
      setState(() => status = "⚠️ Eroare: $e");
    }
  }

  /// Deconectează dispozitivul curent și așteaptă
  Future<void> disconnectAndWait() async {
    if (BleConnectionManager().connectedDevice != null) {
      await BleConnectionManager().connectedDevice?.disconnect();
      BleConnectionManager().clear();
      setState(() {
        status = 'Brățara a fost deconectată. Așteaptă câteva secunde înainte de a scana din nou.';
      });
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      // Bara de sus
      appBar: AppBar(
        title: const Text('Scanare brățară'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleTextStyle: const TextStyle(color: Colors.deepPurple, fontSize: 22, fontWeight: FontWeight.bold),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Card pentru status și buton de rescanare
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(Icons.bluetooth_searching, size: 60, color: Colors.deepPurpleAccent.shade100),
                      const SizedBox(height: 12),
                      Text(status, style: const TextStyle(fontSize: 18, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rescanare'),
                        onPressed: isScanning ? null : startScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Lista dispozitivelor găsite
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: discoveredDevices.isEmpty
                        ? const Center(child: Text('Nicio brățară găsită.',
                            style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: discoveredDevices.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final device = discoveredDevices[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade50,
                                  child: const Icon(Icons.watch,
                                      color: Colors.deepPurple),
                                ),
                                title: Text(device.platformName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple)),
                                trailing: ElevatedButton(
                                  onPressed: () => connectToDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Conectează'),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
