import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;

  void _submit() {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Todos los campos son obligatorios.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }

    // Aquí podrías llamar a tu lógica para guardar la nueva contraseña
    // o redirigir al usuario al login/home

    setState(() => _errorMessage = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Contraseña actualizada con éxito!')),
    );

    // Simular redirección
    Navigator.pop(context); // o pushReplacement a LoginScreen()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '← Volver',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: Image.asset('assets/gym_logo.png', height: 100)),
            const SizedBox(height: 20),
            const Text(
              'Restablecer Contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFD1442F),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFD1442F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contraseña',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Confirmar contraseña',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD1442F),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
