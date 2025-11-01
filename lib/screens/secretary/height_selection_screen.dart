import 'package:flutter/material.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({super.key});

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen> {
  double _height = 170;
  bool _isCm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cuál Es Tu Altura?',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Unit selector
          Container(            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCm = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(                      color: _isCm ? const Color(0xFFFF8C42) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: _isCm
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF8C42).withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: const Text(
                        'CM',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCm = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(                      color: !_isCm ? const Color(0xFFFF8C42) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: !_isCm
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF8C42).withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: const Text(
                        'FT',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Height display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_height.round()}',
                style: const TextStyle(                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isCm ? 'cm' : 'ft',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Height slider with marker lines
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Marker lines
                Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 40),
                  child: CustomPaint(
                    size: const Size(50, 200),                    painter: MarkerLinesPainter(
                      color: const Color(0xFFFF8C42),
                      divisions: 20,
                    ),
                  ),
                ),
                // Slider
                RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,                      thumbColor: const Color(0xFFFF8C42),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 15,
                      ),
                      overlayColor: const Color(0xFFFF8C42).withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 30,
                      ),
                    ),
                    child: Slider(
                      min: 120,
                      max: 220,
                      value: _height,
                      onChanged: (value) {
                        setState(() {
                          _height = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Continue button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'height': _height.round(),
                  'unit': _isCm ? 'cm' : 'ft'
                });
              },              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkerLinesPainter extends CustomPainter {
  final Color color;
  final int divisions;

  MarkerLinesPainter({
    required this.color,
    required this.divisions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    final spacing = size.height / divisions;

    for (var i = 0; i <= divisions; i++) {
      final y = i * spacing;
      final isLongLine = i % 5 == 0;
      final startX = isLongLine ? 0.0 : size.width * 0.5;
      canvas.drawLine(
        Offset(startX, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
