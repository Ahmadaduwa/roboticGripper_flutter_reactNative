import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaterialCard extends StatelessWidget {
  final String materialName;
  final int confidence;

  const MaterialCard({
    super.key,
    required this.materialName,
    required this.confidence,
  });

  // Get icon and colors based on material
  IconData _getMaterialIcon() {
    if (materialName.contains('Metal')) return Icons.hardware;
    if (materialName.contains('Wood')) return Icons.forest;
    if (materialName.contains('Soft') || materialName.contains('Sponge')) {
      return Icons.soap;
    }
    return Icons.category;
  }

  List<Color> _getGradientColors() {
    if (materialName.contains('Metal')) {
      return [const Color(0xFF546E7A), const Color(0xFF37474F)];
    }
    if (materialName.contains('Wood')) {
      return [const Color(0xFF8D6E63), const Color(0xFF5D4037)];
    }
    if (materialName.contains('Soft') || materialName.contains('Sponge')) {
      return [const Color(0xFFEC407A), const Color(0xFFD81B60)];
    }
    return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMaterialIcon(),
            color: Colors.white.withOpacity(0.9),
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                materialName,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Conf: $confidence %',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
