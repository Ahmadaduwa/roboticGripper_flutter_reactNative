import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';
import '../services/api_service.dart';
import '../services/prefs_service.dart';
import '../providers/localization_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AutoRunScreen extends StatefulWidget {
  const AutoRunScreen({super.key});

  @override
  State<AutoRunScreen> createState() => _AutoRunScreenState();
}

class _AutoRunScreenState extends State<AutoRunScreen> {
  final TextEditingController _cyclesController = TextEditingController(
    text: "5",
  );
  final TextEditingController _maxForceController = TextEditingController(
    text: "5.0",
  );
  final TextEditingController _fileController = TextEditingController(
    text: "run_data.csv",
  );

  final FocusNode _cyclesFocus = FocusNode();
  final FocusNode _forceFocus = FocusNode();
  final FocusNode _fileFocus = FocusNode();

  bool _isLoading = false;
  List<dynamic> _patterns = [];
  List<dynamic> _history = [];
  int? _selectedPatternId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _cyclesController.dispose();
    _maxForceController.dispose();
    _fileController.dispose();
    _cyclesFocus.dispose();
    _forceFocus.dispose();
    _fileFocus.dispose();
    super.dispose();
  }

  Future<void> _downloadLog(String filename) async {
    try {
      // Request appropriate storage permission based on Android version
      if (Platform.isAndroid) {
        PermissionStatus status;

        // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
        if (await Permission.manageExternalStorage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.manageExternalStorage.request();

          // If manage external storage is permanently denied, try regular storage
          if (status.isPermanentlyDenied || status.isDenied) {
            status = await Permission.storage.request();
          }
        }

        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Storage permission denied. Please enable in Settings.",
                ),
                action: SnackBarAction(
                  label: "Settings",
                  onPressed: () => openAppSettings(),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Downloading..."),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final baseUrl = await PrefsService.getBaseUrl();
      final url = '$baseUrl/api/logs/download/$filename';

      // Download the file
      final response = await ApiService.client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get the Downloads directory
        Directory? directory;
        if (Platform.isAndroid) {
          // Try standard Downloads folder first
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // Fallback to app-specific directory
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final filePath = '${directory.path}/$filename';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ Downloaded successfully!\n📁 $filePath"),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(label: "OK", onPressed: () {}),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Download failed: ${response.statusCode}"),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error downloading file: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Download error: $e")));
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final patterns = await ApiService.getPatterns();
    final history = await ApiService.getRunHistory();

    if (mounted) {
      setState(() {
        _patterns = patterns;
        _history = history;

        // Ensure _selectedPatternId is valid, or reset it
        if (_patterns.isNotEmpty) {
          final patternIds = _patterns.map((e) => e['id'] as int).toList();

          // If current selection is not in the list, reset to first pattern
          if (_selectedPatternId == null ||
              !patternIds.contains(_selectedPatternId)) {
            _selectedPatternId = patternIds.first;
          }
        } else {
          _selectedPatternId = null; // No patterns available
        }

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 16, right: 16),
            color: const Color(0xFF0047AB),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  localization.t('autoRun'),
                  style: GoogleFonts.zillaSlab(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () =>
                        _fetchData(), // Changed from _fetchHistory to _fetchData to match existing method
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Consumer<RobotProvider>(
                    builder: (context, provider, child) {
                      // Logic:
                      // Ready = Connected + !Running
                      // If Running, show Mode

                      String statusText = "UNKNOWN";
                      Color statusColor = Colors.grey;
                      IconData statusIcon = Icons.help_outline;

                      if (!provider.isConnected) {
                        statusText = localization
                            .t('disconnected')
                            .toUpperCase();
                        statusColor = Colors.red;
                        statusIcon = Icons.signal_wifi_off;
                      } else if (provider.isRunning) {
                        if (provider.controlMode == "TEACHING") {
                          statusText =
                              "${localization.t('teaching_mode').toUpperCase()} ACTIVE";
                          statusColor = Colors.orange;
                          statusIcon = Icons.warning_amber_rounded;
                        } else if (provider.controlMode == "AUTO") {
                          statusText = localization.t('running').toUpperCase();
                          statusColor = Colors.green;
                          statusIcon = Icons.autorenew;
                        } else {
                          statusText = "SYSTEM BUSY";
                          statusColor = Colors.orange;
                          statusIcon = Icons.access_time;
                        }
                      } else {
                        // Not running, Connected
                        statusText = localization
                            .t('system_ready')
                            .toUpperCase();
                        statusColor = Colors.blue;
                        statusIcon = Icons.check_circle_outline;
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 48, color: statusColor),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localization.t('system_status').toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  statusText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Text(
                    localization.t('run_configuration').toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Configuration Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              _buildConfigRow(
                                localization.t('select_pattern'),
                                DropdownButton<int>(
                                  value: _selectedPatternId,
                                  isExpanded: true,
                                  hint: Text(localization.t('select_pattern')),
                                  underline: const SizedBox(),
                                  items: _patterns
                                      .map((e) => e['id'] as int)
                                      .toSet() // Remove duplicates
                                      .map((id) {
                                        final pattern = _patterns.firstWhere(
                                          (e) => e['id'] == id,
                                        );
                                        return DropdownMenuItem<int>(
                                          value: id,
                                          child: Text(
                                            "${pattern['name']}",
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedPatternId = v),
                                ),
                              ),
                              const Divider(height: 32),
                              _buildConfigRow(
                                localization.t('cycle_count'),
                                TextField(
                                  controller: _cyclesController,
                                  focusNode: _cyclesFocus,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  enabled: true,
                                  cursorColor: Colors.blue.shade800,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "5",
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 22,
                                      color: Colors.grey.shade400,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  onChanged: (value) {
                                    // Just update the value
                                    setState(() {});
                                  },
                                ),
                              ),
                              const Divider(height: 32),
                              _buildConfigRow(
                                localization.t('force_limit'),
                                TextField(
                                  controller: _maxForceController,
                                  focusNode: _forceFocus,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  enabled: true,
                                  cursorColor: Colors.blue.shade800,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "5.0",
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 22,
                                      color: Colors.grey.shade400,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              const Divider(height: 32),
                              _buildConfigRow(
                                localization.t('log_filename'),
                                TextField(
                                  controller: _fileController,
                                  focusNode: _fileFocus,
                                  textAlign: TextAlign.end,
                                  enabled: true,
                                  cursorColor: Colors.blue.shade800,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "run.csv",
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 32),

                  // Start/Stop Button
                  Consumer<RobotProvider>(
                    builder: (context, provider, _) {
                      // Determine if auto run is currently running
                      final bool isAutoRunning =
                          provider.isRunning && provider.controlMode == "AUTO";

                      // Can start if: connected, not running, and pattern selected
                      final bool canStart =
                          provider.isConnected &&
                          !provider.isRunning &&
                          _selectedPatternId != null;

                      // Can stop if: auto run is currently running
                      final bool canStop = isAutoRunning;

                      // Button is enabled if can start OR can stop
                      final bool isEnabled = canStart || canStop;

                      return SizedBox(
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: isEnabled
                              ? () async {
                                  if (isAutoRunning) {
                                    // STOP AUTO RUN
                                    setState(() => _isLoading = true);
                                    final success =
                                        await ApiService.stopAutoRun();

                                    // Refresh data
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                    await _fetchData();
                                    setState(() => _isLoading = false);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? localization.t(
                                                    'auto_run_stopped',
                                                  )
                                                : "Failed to stop Auto Run",
                                          ),
                                          backgroundColor: success
                                              ? Colors.orange
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    // START AUTO RUN
                                    final cycles =
                                        int.tryParse(_cyclesController.text) ??
                                        5;
                                    final maxF =
                                        double.tryParse(
                                          _maxForceController.text,
                                        ) ??
                                        5.0;
                                    final fname = _fileController.text;

                                    setState(() => _isLoading = true);
                                    final success =
                                        await ApiService.startAutoRun(
                                          _selectedPatternId!,
                                          cycles: cycles,
                                          maxForce: maxF,
                                          filename: fname,
                                        );

                                    // Refresh logs after brief delay
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                    await _fetchData();
                                    setState(() => _isLoading = false);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? "Auto Run Started!"
                                                : "Failed to start Auto Run",
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null, // Disable if neither can start nor stop
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEnabled
                                ? (isAutoRunning
                                      ? Colors
                                            .red
                                            .shade700 // Red for STOP
                                      : const Color(
                                          0xFF0D47A1,
                                        )) // Blue for START
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          icon: Icon(
                            isAutoRunning
                                ? Icons
                                      .stop_rounded // Stop icon
                                : Icons.play_arrow_rounded, // Play icon
                            size: 32,
                            color: Colors.white,
                          ),
                          label: Text(
                            isAutoRunning
                                ? localization.t('stop_auto_run')
                                : localization.t('start_auto_run'),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Recent Logs List
                  Text(
                    localization.t('execution_logs'),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          "No logs found",
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    ),

                  ..._history.map(
                    (h) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: h['status'] == 'Running'
                              ? Colors.green.shade100
                              : Colors.blue.shade50,
                          child: Icon(
                            Icons.insert_drive_file,
                            color: h['status'] == 'Running'
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                        title: Text(
                          h['filename'] ?? "log.csv",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${h['pattern_name']} • ${h['cycle_completed']}/${h['cycle_target']} • ${h['status']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Download Button (Placeholder)
                            IconButton(
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _downloadLog(h['filename']);
                              },
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      localization.t('confirm_delete'),
                                    ),
                                    content: Text(
                                      "${localization.t('are_you_sure_delete')} ${h['filename']}?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(localization.t('cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          localization.t('delete'),
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await ApiService.deleteRunHistory(h['id']);
                                  _fetchData(); // Refresh list
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, Widget child) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        SizedBox(width: 160, child: child),
      ],
    );
  }
}
