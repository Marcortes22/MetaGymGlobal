import 'package:flutter/material.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:gym_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _showRenewalMessage = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _showRenewalMessage = false;
    });

    try {
      final result = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        if (result['warning'] != null) {
          // Mostrar el warning en un SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['warning']),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        setState(() {
          _error = result['message'];
          _showRenewalMessage = result['requiresRenewal'] ?? false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al iniciar sesión';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed:
              () => Navigator.pushReplacementNamed(context, AppRoutes.welcome),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/gym_logo.png', height: 120),
                const SizedBox(height: 30),
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C42)),
                    ),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color(0xFFFF8C42),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF8C42)),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFFFF8C42),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFFFF8C42),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: Color(0xFFFF8C42),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_showRenewalMessage) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Por favor, visite el gimnasio para renovar su membresía.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
