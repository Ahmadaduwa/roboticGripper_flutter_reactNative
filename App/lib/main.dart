import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/robot_provider.dart';
import 'providers/teaching_provider.dart';
import 'screens/main_layout.dart';
import 'services/api_service.dart';
import 'services/database_service.dart';
import 'models/pattern.dart';

void main() {
  runApp(const RoboticGripperApp());
}

class RoboticGripperApp extends StatelessWidget {
  const RoboticGripperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RobotProvider()),
        ChangeNotifierProvider(create: (_) => TeachingProvider()),
      ],
      child: MaterialApp(
        title: 'Robotic Gripper',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.outfitTextTheme(),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = "Checking connection...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _status = "Connecting to Simulation...";
      _hasError = false;
    });

    try {
      // 1. Check Connectivity
      final isOnline = await ApiService.checkBackendAvailable();
      if (!isOnline) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _status =
                "Cannot connect to Simulation Backend.\nPlease ensure simulation.py is running.";
          });
        }
        return;
      }

      // 2. Sync Data
      if (mounted) setState(() => _status = "Syncing Database...");

      // Pull from Backend
      final patternsJson = await ApiService.pullPatterns();

      // Clear Local DB
      await DatabaseService.instance.clearAllData();

      // Save to Local DB
      int count = 0;
      for (var pJson in patternsJson) {
        try {
          // Parse JSON to Pattern Model
          // Ensure 'steps' are included in pJson map from backend
          final pattern = Pattern.fromJson(pJson);
          await DatabaseService.instance.savePattern(pattern);
          count++;
        } catch (e) {
          debugPrint("Error syncing pattern: $e");
        }
      }

      debugPrint("Synced $count patterns.");

      // 3. Navigate
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _status = "Initialization Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_hasError) ...[
                const Icon(
                  Icons.signal_wifi_off,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  "Connection Failed",
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _initializeApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry Connection"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 32),
                Text(
                  _status,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
