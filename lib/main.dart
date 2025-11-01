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

  // Inicializar Firebase solo si no existe ninguna app
  // Esto previene el error duplicate-app en hot restart
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase inicializado correctamente");
    } catch (e) {
      debugPrint("❌ Error al inicializar Firebase: $e");
    }
  } else {
    debugPrint(
      "✅ Firebase ya estaba inicializado (${Firebase.apps.length} apps)",
    );
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
  Timer? _totenModeCheckTimer;

  @override
  void initState() {
    super.initState();
    _isTotenMode = widget.isToten;
    // Set up a listener to check for shared preferences changes
    _checkTotenModePreference();

    // Set up periodic check for totem mode changes
    _totenModeCheckTimer = Timer.periodic(
      const Duration(seconds: 2), // Check every 2 seconds
      (_) => _checkTotenModePreference(),
    );
  }

  @override
  void dispose() {
    _totenModeCheckTimer?.cancel();
    super.dispose();
  }

  // Check totem mode preference periodically
  Future<void> _checkTotenModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isTotenMode = prefs.getBool('modo_toten') ?? false;

    if (mounted && _isTotenMode != isTotenMode) {
      setState(() {
        _isTotenMode = isTotenMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _checkingTotenMode = true;
  bool _isTotenMode = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkTotenMode();
  }

  Future<void> _checkTotenMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isTotenMode = prefs.getBool('modo_toten') ?? false;

    if (mounted) {
      setState(() {
        _isTotenMode = isTotenMode;
        _checkingTotenMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're still checking totem mode preference, show loading
    if (_checkingTotenMode) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If totem mode is active, show CheckInScreen directly
    if (_isTotenMode) {
      return const CheckInScreen();
    }

    // Otherwise proceed with normal authentication flow
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<List<String?>>(
          future: _authService.getUserRoles(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final roles = roleSnapshot.data ?? [];

            if (roles.isEmpty) {
              return const NoRoleScreen();
            }
            if (roles.length == 1) {
              switch (roles.first) {
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
            // Si hay más de un rol, mostrar pantalla de selección
            return RoleSelectionScreen(
              roles: roles.whereType<String>().toList(),
            );
          },
        );
      },
    );
  }
}
