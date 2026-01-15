import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom Header MATCHING DashboardScreen
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 50,
            bottom: 20,
          ), // Status bar padding
          color: const Color(0xFF0047AB), // Cobalt Blue from Dashboard
          alignment: Alignment.center,
          child: Text(
            "Manual Control",
            style: GoogleFonts.zillaSlab(
              // Serif-like font match
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        Expanded(
          child: Consumer<RobotProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Max Force Section
                    Text(
                      "Max Force",
                      style: GoogleFonts.zillaSlab(
                        // Consistent Typography
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "${provider.maxForce.toStringAsFixed(2)} N",
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        activeTrackColor: Colors.lightBlueAccent,
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.blue,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: provider.maxForce,
                        min: 0,
                        max: 10,
                        divisions: 1000, // 0.01 precision
                        onChanged: (val) {
                          provider.updateControl(
                            gripperPos: provider.gripperPosition,
                            maxForce: val,
                            isOn: provider.isSystemOn,
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "0 N",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "10 N",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // 2. Gripper Position Section
                    Text(
                      "Gripper",
                      style: GoogleFonts.zillaSlab(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "${provider.gripperPosition.toStringAsFixed(2)}°",
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        activeTrackColor: Colors.lightBlueAccent,
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.blue,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: provider.gripperPosition.toDouble(),
                        min: 0,
                        max: 180,
                        divisions: 18000, // 0.01 precision
                        onChanged: (val) {
                          provider.updateControl(
                            gripperPos: val,
                            maxForce: provider.maxForce,
                            isOn: provider.isSystemOn,
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Squeeze (0°)",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Release (180°)",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // 3. Power Switch (Big Green Button)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          provider.updateControl(
                            gripperPos: provider.gripperPosition,
                            maxForce: provider.maxForce,
                            isOn: !provider.isSystemOn,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 250, // Slightly wider
                          height: 90,
                          decoration: BoxDecoration(
                            color: provider.isSystemOn
                                ? const Color(0xFF00C853)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (provider.isSystemOn
                                            ? Colors.green
                                            : Colors.grey)
                                        .withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                left: provider.isSystemOn
                                    ? 160
                                    : 10, // Adjusted for width
                                top: 10,
                                bottom: 10, // Added bottom/top alignment
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  provider.isSystemOn ? "ON" : "OFF",
                                  style: GoogleFonts.outfit(
                                    fontSize: 36, // Bigger
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Navbar label mock (bottom blue, if requested, but MainLayout handles Nav)
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
