import 'package:flutter/material.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({super.key});

  @override
  State<WeightSelectionScreen> createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen> {
  double _weight = 75;
  bool _isKg = true;

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
          'Cuál Es Tu Peso?',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Unidad de medida selector
          Container(            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isKg = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(                        color: _isKg ? const Color(0xFFFF8C42) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: _isKg
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
                        'KG',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isKg = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(                        color: !_isKg ? const Color(0xFFFF8C42) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: !_isKg
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
                        'LB',
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
          // Weight display
          Text(
            '${_weight.round()}',              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _isKg ? 'Kg' : 'Lb',              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[400],
            ),
          ),
          const Spacer(),
          // Weight slider
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(                  height: 2,
                  color: const Color(0xFFFF8C42),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: const Color(0xFFFF8C42),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 15,
                    ),
                    overlayColor: const Color(0xFFFF8C42).withOpacity(0.2),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 30,
                    ),
                  ),
                  child: Slider(
                    min: 30,
                    max: 200,
                    value: _weight,
                    onChanged: (value) {
                      setState(() {
                        _weight = value;
                      });
                    },
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
                  'weight': _weight.round(),
                  'unit': _isKg ? 'kg' : 'lb'
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
