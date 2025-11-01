import 'package:flutter/material.dart';

class KioskModeModal extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const KioskModeModal({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  // Feature item widget with icon and text
  static Widget _FeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C42), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF2A2A2A),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C42).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phonelink_lock,
              color: Color(0xFFFF8C42),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Activar Modo Asistencia',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Al activar el Modo Asistencia, la aplicación:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _FeatureItem(
              icon: Icons.check_circle_outline,
              text: 'Se convertirá en una terminal de check-in',
            ),
            _FeatureItem(icon: Icons.logout, text: 'Cerrará tu sesión actual'),
            _FeatureItem(
              icon: Icons.qr_code,
              text: 'Mostrará el código QR y teclado numérico',
            ),
            _FeatureItem(
              icon: Icons.touch_app,
              text: 'Se activará inmediatamente sin necesidad de reiniciar',
            ),
            const SizedBox(height: 16),
            const Text(
              'Para desactivar este modo, mantén presionado el icono de configuración (⚙️) en la esquina de la pantalla de check-in durante unos segundos.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8C42), Color(0xFFFFA45C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: onConfirm,
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
