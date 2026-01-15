import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/teaching_provider.dart';
import '../providers/robot_provider.dart';
import '../models/pattern.dart';

class TeachingScreen extends StatefulWidget {
  const TeachingScreen({super.key});

  @override
  State<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen> {
  bool _isDetailView = false;
  final TextEditingController _waitController = TextEditingController(text: "1.0");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeachingProvider>().refreshPatterns();
      }
    });
  }

  @override
  void dispose() {
    _waitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isDetailView ? 'Edit Pattern' : 'Teaching Mode',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        leading: _isDetailView
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _isDetailView = false),
              )
            : null,
        actions: [
          if (!_isDetailView)
            Consumer<TeachingProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: provider.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.sync, color: Colors.white),
                  onPressed: provider.isSyncing
                      ? null
                      : () async {
                          final success = await provider.syncWithBackend();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Synced successfully!'
                                      : 'Sync failed: ${provider.lastSyncError ?? "Unknown error"}',
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                );
              },
            ),
        ],
      ),
      body: Consumer<TeachingProvider>(
        builder: (context, provider, child) {
          return _isDetailView
              ? _buildDetailView(context, provider)
              : _buildListView(context, provider);
        },
      ),
    );
  }

  // ==================== Pattern List View ====================
  
  Widget _buildListView(BuildContext context, TeachingProvider provider) {
    if (provider.isLoadingPatterns) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("Saved Patterns (${provider.patternCount})"),
        const SizedBox(height: 12),
        
        if (provider.patterns.isEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No patterns yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first pattern to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          ...provider.patterns.map(
            (pattern) => _buildPatternCard(context, pattern, provider),
          ),

        const SizedBox(height: 24),
        
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              _showCreatePatternDialog(context, provider);
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              "CREATE NEW PATTERN",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternCard(BuildContext context, Pattern pattern, TeachingProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0D47A1),
          child: Text(
            '${pattern.stepCount}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          pattern.name,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pattern.description != null)
              Text(
                pattern.description!,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Modified: ${pattern.lastModified} • ${pattern.stepCount} steps',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, pattern, provider),
        ),
        onTap: () async {
          await provider.loadPattern(pattern.id!);
          setState(() => _isDetailView = true);
        },
      ),
    );
  }

  // ==================== Pattern Detail/Editor View ====================
  
  Widget _buildDetailView(BuildContext context, TeachingProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pattern Info Card
          _buildPatternInfoCard(provider),
          const SizedBox(height: 24),

          // Action Controller Section
          _buildSectionHeader("Action Controller"),
          const SizedBox(height: 12),
          _buildActionController(provider),
          const SizedBox(height: 24),

          // Sequence Controls
          _buildSectionHeader("Recorded Sequence (${provider.bufferStepCount} steps)"),
          const SizedBox(height: 12),
          _buildSequenceList(provider),
          const SizedBox(height: 24),

          // Testing Area
          _buildTestingArea(provider),
          const SizedBox(height: 24),

          // Save Button
          _buildSaveButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildPatternInfoCard(TeachingProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pattern Name",
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            TextField(
              controller: TextEditingController(
                text: provider.currentPattern?.name ?? 'New Pattern',
              )..selection = TextSelection.fromPosition(
                  TextPosition(
                    offset: provider.currentPattern?.name.length ?? 0,
                  ),
                ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (val) => provider.updatePatternName(val),
            ),
            const SizedBox(height: 16),
            Text(
              "Description (Optional)",
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            TextField(
              controller: TextEditingController(
                text: provider.currentPattern?.description ?? '',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Add a description...',
              ),
              style: GoogleFonts.outfit(fontSize: 14),
              maxLines: 2,
              onChanged: (val) => provider.updatePatternDescription(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionController(TeachingProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle Grip/Release and Add Position Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: provider.isGripMode ? "ADD GRIP" : "ADD RELEASE",
                    icon: provider.isGripMode ? Icons.compress : Icons.expand,
                    color: provider.isGripMode ? Colors.orange.shade700 : Colors.blue.shade700,
                    onTap: () {
                      if (provider.isGripMode) {
                        provider.addGripStep(0); // 0 = closed
                        _showSnackBar('Grip step added');
                      } else {
                        provider.addReleaseStep(180); // 180 = open
                        _showSnackBar('Release step added');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: "ADD POSITION",
                    icon: Icons.location_on,
                    color: Colors.green.shade700,
                    onTap: () async {
                      final success = await provider.addCurrentPosition();
                      if (success) {
                        _showSnackBar('Position saved!');
                      } else {
                        _showSnackBar('Failed to get position');
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Wait Timer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _waitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Wait Duration (seconds)",
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final duration = double.tryParse(_waitController.text) ?? 1.0;
                      provider.addWaitStep(duration);
                      _showSnackBar('Wait step added (${duration}s)');
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("ADD WAIT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequenceList(TeachingProvider provider) {
    if (provider.recordingBuffer.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No steps recorded',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the controls above to add steps',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Clear all button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Steps',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmClearBuffer(context, provider),
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.recordingBuffer.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final step = provider.recordingBuffer[index];
              final isExecuting = provider.isExecuting && provider.currentExecutingStep == index;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isExecuting 
                      ? Colors.green 
                      : _getStepColor(step.actionType),
                  child: isExecuting
                      ? const Icon(Icons.play_arrow, color: Colors.white, size: 20)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                title: Text(
                  step.description,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  step.actionType.toUpperCase(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      onPressed: index > 0 ? () => provider.moveStepUp(index) : null,
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      onPressed: index < provider.recordingBuffer.length - 1
                          ? () => provider.moveStepDown(index)
                          : null,
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => provider.deleteStep(index),
                      color: Colors.red,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestingArea(TeachingProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Testing Area",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: provider.recordingBuffer.isEmpty || provider.isExecuting
                    ? null
                    : () async {
                        final robot = context.read<RobotProvider>();
                        
                        // 1. Save current Manual Control state
                        final previousSystemState = robot.isSystemOn;
                        
                        // 2. Force Manual Control OFF
                        await robot.forceSystemOff();
                        
                        // 3. Execute sequence
                        final success = await provider.executeOnBackend(
                          maxForce: robot.maxForce,
                          gripperAngle: robot.gripperPosition,
                          isOn: robot.isSystemOn,
                        );
                        
                        // 4. Restore original Manual Control state
                        await robot.restoreSystemState(previousSystemState);
                        
                        if (mounted) {
                          _showSnackBar(
                            success ? 'Execution completed' : 'Execution failed',
                          );
                        }
                      },
                icon: provider.isExecuting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow, color: Colors.white),
                label: Text(
                  provider.isExecuting ? "EXECUTING..." : "PLAY SEQUENCE",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, TeachingProvider provider) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          final success = await provider.saveCurrentPattern();
          if (mounted) {
            if (success) {
              _showSnackBar('Pattern saved successfully!');
              setState(() => _isDetailView = false);
            } else {
              _showSnackBar('Failed to save pattern');
            }
          }
        },
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          "SAVE PATTERN",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // ==================== Helper Widgets & Methods ====================

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }

  Color _getStepColor(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'grip':
        return Colors.orange.shade700;
      case 'release':
        return Colors.blue.shade700;
      case 'wait':
        return Colors.purple.shade700;
      case 'move_joints':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showCreatePatternDialog(BuildContext context, TeachingProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Pattern', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Pattern Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.createNewPattern(
                  nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                );
                Navigator.pop(context);
                setState(() => _isDetailView = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Pattern pattern, TeachingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Pattern', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${pattern.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (pattern.id != null) {
                await provider.deletePattern(pattern.id!);
                if (mounted) {
                  _showSnackBar('Pattern deleted');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearBuffer(BuildContext context, TeachingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Steps', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to clear all steps?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearBuffer();
              Navigator.pop(context);
              _showSnackBar('All steps cleared');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ==================== Custom Action Button Widget ====================

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

