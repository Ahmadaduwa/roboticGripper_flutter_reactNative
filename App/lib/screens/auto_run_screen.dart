import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';
import '../services/api_service.dart';

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

  bool _isLoading = false;
  List<dynamic> _patterns = [];
  List<dynamic> _history = [];
  int? _selectedPatternId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final patterns = await ApiService.getPatterns();
    final history = await ApiService.getRunHistory();

    if (mounted) {
      setState(() {
        _patterns = patterns;
        _history = history;
        if (_patterns.isNotEmpty && _selectedPatternId == null) {
          _selectedPatternId = _patterns.first['id'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Auto Run Control',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1), // Deep Blue
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
                  statusText = "DISCONNECTED";
                  statusColor = Colors.red;
                  statusIcon = Icons.signal_wifi_off;
                } else if (provider.isRunning) {
                  if (provider.controlMode == "TEACHING") {
                    statusText = "TEACHING ACTIVE";
                    statusColor = Colors.orange;
                    statusIcon = Icons.warning_amber_rounded;
                  } else if (provider.controlMode == "AUTO") {
                    statusText = "AUTO RUNNING";
                    statusColor = Colors.green;
                    statusIcon = Icons.autorenew;
                  } else {
                    statusText = "SYSTEM BUSY";
                    statusColor = Colors.orange;
                    statusIcon = Icons.access_time;
                  }
                } else {
                  // Not running, Connected
                  statusText = "READY TO START";
                  statusColor = Colors.blue;
                  statusIcon = Icons.check_circle_outline;
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
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
                            "SYSTEM STATUS",
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
              "CONFIGURATION",
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
                          "Pattern ID",
                          DropdownButton<int>(
                            value: _selectedPatternId,
                            isExpanded: true,
                            hint: const Text("Select Pattern"),
                            underline: const SizedBox(),
                            items: _patterns
                                .map(
                                  (e) => DropdownMenuItem<int>(
                                    value: e['id'] as int,
                                    child: Text(
                                      "${e['name']}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedPatternId = v),
                          ),
                        ),
                        const Divider(height: 32),
                        _buildConfigRow(
                          "Target Cycles",
                          TextField(
                            controller: _cyclesController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "5",
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const Divider(height: 32),
                        _buildConfigRow(
                          "Force Limit (N)",
                          TextField(
                            controller: _maxForceController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "5.0",
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const Divider(height: 32),
                        _buildConfigRow(
                          "Log Filename",
                          TextField(
                            controller: _fileController,
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "run.csv",
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 32),

            // Start/Stop Button
            Consumer<RobotProvider>(
              builder: (context, provider, _) {
                final bool canRun =
                    provider.isConnected &&
                    !provider.isRunning &&
                    _selectedPatternId != null;

                return SizedBox(
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: canRun
                        ? () async {
                            final cycles =
                                int.tryParse(_cyclesController.text) ?? 5;
                            final maxF =
                                double.tryParse(_maxForceController.text) ??
                                5.0;
                            final fname = _fileController.text;

                            setState(() => _isLoading = true);
                            // Call API Service
                            final success = await ApiService.startAutoRun(
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
                              ScaffoldMessenger.of(context).showSnackBar(
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
                        : null, // Disable if not ready
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRun
                          ? const Color(0xFF0D47A1)
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                    label: Text(
                      "START AUTO RUN",
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
              "RECENT EXECUTION LOGS",
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
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
                          // TODO: Implement actual download or file open
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
                              title: const Text("Delete Record?"),
                              content: Text(
                                "This will permanently delete ${h['filename']}. Are you sure?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Delete",
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
