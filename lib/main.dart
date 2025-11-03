import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gym_app/firebase_options.dart';
import 'package:gym_app/screens/auth/CheckInScreen.dart';
import 'package:gym_app/screens/client/client_home_screen.dart';
import 'package:gym_app/screens/coach/coach_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/screens/auth/no_role_screen.dart';
import 'package:gym_app/screens/owner/owner_home_screen.dart';
import 'package:gym_app/screens/auth/role_selection_screen.dart';
import 'package:gym_app/screens/secretary/secretary_home_screen.dart';
import 'package:gym_app/screens/auth/welcome_screen.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:gym_app/providers/gym_context_provider.dart';

import 'package:gym_app/services/service_locator.dart';
import 'package:gym_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env opcional - no bloquea si falta
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ .env no encontrado o vacío: $e");
  }

  // Inicializar Firebase de forma segura
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase inicializado correctamente");
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint("✅ Firebase ya estaba inicializado");
    } else {
      debugPrint("❌ Error al inicializar Firebase: $e");
      rethrow; // Re-lanzar si es un error real
    }
  }

  ServiceLocator.setupServices();

  final prefs = await SharedPreferences.getInstance();
  final bool isToten = prefs.getBool('modo_toten') ?? false;

  runApp(MyApp(isToten: isToten));
}

class MyApp extends StatefulWidget {
  final bool isToten;

  const MyApp({super.key, required this.isToten});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isTotenMode;

  @override
  void initState() {
    super.initState();
    _isTotenMode = widget.isToten;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GymContextProvider(),
      child: MaterialApp(
        title: 'Gym App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => _isTotenMode ? const CheckInScreen() : const RootPage(),
          ...AppRoutes.routes,
        },
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final _authService = AuthService();
  User? _currentUser;
  List<String?>? _userRoles;
  bool _isLoadingRoles = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 RootPage initState');
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('👤 Usuario actual: ${_currentUser?.uid ?? "NINGUNO"}');

      if (_currentUser != null) {
        await _loadUserRoles();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error inicializando auth: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _loadUserRoles() async {
    if (_isLoadingRoles) return;

    debugPrint('🔄 Iniciando carga de roles...');
    setState(() => _isLoadingRoles = true);

    try {
      final roles = await _authService
          .getUserRoles(_currentUser!.uid)
          .timeout(const Duration(seconds: 5));

      debugPrint('✅ Roles cargados: $roles');

      if (mounted) {
        setState(() {
          _userRoles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando roles: $e');

      // Si hay error, hacer logout automático
      try {
        await FirebaseAuth.instance.signOut();
        debugPrint('🔥 Logout automático por error de roles');
      } catch (_) {}

      if (mounted) {
        setState(() {
          _userRoles = [];
          _isLoadingRoles = false;
          _currentUser = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading mientras inicializa
    if (!_isInitialized) {
      debugPrint('⏳ Esperando inicialización...');
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Si no hay usuario, mostrar welcome directamente
    if (_currentUser == null) {
      debugPrint('➡️ Mostrando WelcomeScreen (no hay usuario)');
      return const WelcomeScreen();
    }

    // Si hay usuario pero no hay roles cargados, mostrar loading
    if (_userRoles == null) {
      debugPrint('⏳ Cargando roles...');
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Si no hay roles, mostrar welcome
    if (_userRoles!.isEmpty) {
      debugPrint('➡️ Mostrando WelcomeScreen (sin roles)');
      return const WelcomeScreen();
    }

    debugPrint('✅ Navegando a home screen con roles: $_userRoles');

    // Navegar según roles
    if (_userRoles!.length == 1) {
      switch (_userRoles!.first) {
        case 'cli':
          return const ClientHomeScreen();
        case 'own':
          return const OwnerHomeScreen();
        case 'coa':
          return const CoachHomeScreen();
        case 'sec':
          return const SecretaryHomeScreen();
        default:
          return const NoRoleScreen();
      }
    }

    // Múltiples roles
    return RoleSelectionScreen(roles: _userRoles!.whereType<String>().toList());
  }
}
