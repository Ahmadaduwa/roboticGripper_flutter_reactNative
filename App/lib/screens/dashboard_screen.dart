import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';
import '../widgets/force_graph.dart';
import '../widgets/force_indicator.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom Header matches visual reference
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 50,
            bottom: 16,
          ),
          color: const Color(0xFF0047AB),
          alignment: Alignment.center,
          child: Text(
            "Dashboard",
            style: GoogleFonts.zillaSlab(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Non-scrollable Body with optimized layout
        Expanded(
          child: Consumer<RobotProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 5),
                    // 1. Force Indicator
                    Center(
                      child: ForceIndicator(
                        forceValue: provider.force,
                        size: 160,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 2. Material & Confidence
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047AB),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            provider.material,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Conf: ${provider.confidence.toStringAsFixed(2)} %",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 3. Real-time Graph
                    SizedBox(
                      height: 300,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ForceGraph(
                                  spots: provider.spots,
                                  lineColor: Colors.black,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              top: 70,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  "Force",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  "Time",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
