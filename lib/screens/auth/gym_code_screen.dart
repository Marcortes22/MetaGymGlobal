import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:gym_app/models/gym.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GymCodeScreen extends StatefulWidget {
  const GymCodeScreen({super.key});

  @override
  State<GymCodeScreen> createState() => _GymCodeScreenState();
}

class _GymCodeScreenState extends State<GymCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isValidating = false;
  String? _error;
  Gym? _validatedGym;

  // Gimnasio guardado anteriormente
  String? _savedGymId;
  String? _savedGymName;
  String? _savedCode;
  bool _showSavedGym = false;

  @override
  void initState() {
    super.initState();
    _loadSavedGym();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Cargar gimnasio guardado anteriormente
  Future<void> _loadSavedGym() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGymId = prefs.getString('current_gym_id');
      final savedGymName = prefs.getString('gym_name');
      final savedCode = prefs.getString('gym_code');

      if (savedGymId != null && savedGymName != null) {
        setState(() {
          _savedGymId = savedGymId;
          _savedGymName = savedGymName;
          _savedCode = savedCode;
          _showSavedGym = true;
        });
      }
    } catch (e) {
      // Si hay error, simplemente no mostramos el gym guardado
      print('Error cargando gym guardado: $e');
    }
  }

  // Usar gimnasio guardado
  Future<void> _useSavedGym() async {
    if (_savedGymId == null) return;

    setState(() => _isLoading = true);

    try {
      // Obtener datos completos del gym
      final gymDoc =
          await FirebaseFirestore.instance
              .collection('gyms')
              .doc(_savedGymId)
              .get();

      if (gymDoc.exists && gymDoc.data()?['is_active'] == true) {
        final gym = Gym.fromFirestore(gymDoc);
        _navigateToLogin(gym);
      } else {
        setState(() {
          _error = 'El gimnasio guardado ya no está disponible';
          _showSavedGym = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el gimnasio guardado';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin(Gym gym) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: {
        'gymId': gym.id,
        'tenantId': gym.tenantId,
        'gymName': gym.name,
        'code': gym.code, // Usar code en lugar de shortCode
      },
    );
  }

  Future<void> _validateGymCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _error = 'Por favor ingresa un código';
        _validatedGym = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _error = null;
      _validatedGym = null;
    });

    try {
      // Buscar el gimnasio por code (no shortCode)
      final gymQuery =
          await FirebaseFirestore.instance
              .collection('gyms')
              .where('code', isEqualTo: code)
              .where('is_active', isEqualTo: true)
              .limit(1)
              .get();

      if (gymQuery.docs.isEmpty) {
        setState(() {
          _error = 'Código de gimnasio no válido';
          _validatedGym = null;
        });
      } else {
        final gym = Gym.fromFirestore(gymQuery.docs.first);
        setState(() {
          _validatedGym = gym;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al validar el código';
        _validatedGym = null;
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  void _continueToLogin() {
    if (_validatedGym == null) {
      setState(() {
        _error = 'Por favor valida el código primero';
      });
      return;
    }

    _navigateToLogin(_validatedGym!);
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
                  'Selecciona tu Gimnasio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingresa el código de tu gimnasio',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                // Mostrar gimnasio guardado si existe
                if (_showSavedGym && _savedGymName != null) ...[
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF8C42).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C42),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Último gimnasio usado',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _savedGymName!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_savedCode != null)
                                    Text(
                                      _savedCode!,
                                      style: const TextStyle(
                                        color: Color(0xFFFF8C42),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _useSavedGym,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8C42),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Continuar con este gimnasio'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.3)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O ingresa otro código',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 40),
                TextField(
                  controller: _codeController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'GYM001',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 2,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            _validatedGym != null
                                ? Colors.green
                                : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF8C42),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFFF8C42),
                    ),
                    suffixIcon:
                        _validatedGym != null
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : null,
                  ),
                  onChanged: (value) {
                    // Limpiar validación cuando cambia el texto
                    if (_validatedGym != null || _error != null) {
                      setState(() {
                        _validatedGym = null;
                        _error = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _validateGymCode(),
                ),
                const SizedBox(height: 20),

                // Botón de validar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isValidating ? null : _validateGymCode,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFFF8C42),
                        width: 2,
                      ),
                      foregroundColor: Color(0xFFFF8C42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child:
                        _isValidating
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF8C42),
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Validar Código',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),

                // Mensaje de error
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Información del gimnasio validado
                if (_validatedGym != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C42),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _validatedGym!.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_validatedGym!.city}, ${_validatedGym!.country}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFFF8C42),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _validatedGym!.address,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Botón continuar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _validatedGym != null && !_isLoading
                            ? _continueToLogin
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Continuar al Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Ayuda
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: Color(0xFFFF8C42),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '¿No tienes un código?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contacta a tu gimnasio para obtener tu código de acceso',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
