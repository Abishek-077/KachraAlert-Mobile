import 'package:flutter/material.dart';
import 'package:smart_waste_app/core/widgets/k_widgets.dart';

/// Map tab.
/// Real map integration is feature-flagged; for now we render a
/// high-quality UI placeholder that matches the reference screenshot.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background "map" placeholder (soft grid)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.surface.withOpacity(0.92),
                    cs.surface,
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _GridPainter(color: cs.outlineVariant.withOpacity(0.28)),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Map View',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.remove_red_eye_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _CircleIconButton(
                    icon: Icons.layers_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // Pins
          Positioned(
            left: 78,
            top: 210,
            child: _Pin(color: const Color(0xFFF5A623)),
          ),
          Positioned(
            left: 190,
            top: 320,
            child: _Pin(color: const Color(0xFF0E6E66)),
          ),
          Positioned(
            left: 215,
            top: 450,
            child: _Pin(color: const Color(0xFF1ECA92)),
          ),
          Positioned(
            left: 150,
            top: 520,
            child: _Pin(color: const Color(0xFF1B8EF2)),
          ),

          // Right-side controls
          Positioned(
            right: 16,
            top: 420,
            child: Column(
              children: [
                _CircleIconButton(icon: Icons.add_rounded, onTap: () {}),
                const SizedBox(height: 12),
                _CircleIconButton(icon: Icons.remove_rounded, onTap: () {}),
                const SizedBox(height: 18),
                FloatingActionButton(
                  heroTag: 'loc',
                  onPressed: () {},
                  elevation: 0,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  child: const Icon(Icons.near_me_rounded),
                ),
              ],
            ),
          ),

          // Bottom info card
          Positioned(
            left: 16,
            right: 16,
            bottom: 92, // keep above bottom dock
            child: KCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kathmandu Metro',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 active reports in view',
                          style: TextStyle(color: cs.onSurface.withOpacity(0.62)),
                        ),
                      ],
                    ),
                  ),
                  _CountBubble(count: '12', color: const Color(0xFFF5A623)),
                  const SizedBox(width: 10),
                  _CountBubble(count: '3', color: const Color(0xFF0E6E66)),
                  const SizedBox(width: 10),
                  _CountBubble(count: '24', color: const Color(0xFF1ECA92)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: cs.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.10),
              ),
            ],
          ),
          child: Icon(icon, color: cs.onSurface.withOpacity(0.72)),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.place_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count, required this.color});
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        count,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const spacing = 150.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.color != color;
}
