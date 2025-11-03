import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import '../services/service_locator.dart';
import '../services/gym_service.dart';

class AuthService {
  late final FirebaseAuth _auth;
  late final SubscriptionService _subscriptionService;
  late final FirebaseFirestore _firestore;
  late final GymService _gymService;

  AuthService({
    FirebaseAuth? auth,
    SubscriptionService? subscriptionService,
    FirebaseFirestore? firestore,
    GymService? gymService,
  }) {
    final serviceLocator = ServiceLocator();
    _auth =
        auth ??
        serviceLocator.getService<FirebaseAuth>() ??
        FirebaseAuth.instance;
    _subscriptionService =
        subscriptionService ??
        serviceLocator.getService<SubscriptionService>() ??
        SubscriptionService();
    _firestore =
        firestore ??
        serviceLocator.getService<FirebaseFirestore>() ??
        FirebaseFirestore.instance;
    _gymService = gymService ?? GymService();
  }

  // Obtener roles del usuario
  Future<List<String>> getUserRoles(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data();
      final rolesData = data?['roles'] as List<dynamic>?;

      if (rolesData != null && rolesData.isNotEmpty) {
        // Extrae el ID de cada rol
        return rolesData
            .map((role) => role['id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();
      }
    }

    return []; // Si no hay roles, devolvés una lista vacía
  }

  // Verifica si un usuario es solo cliente
  Future<bool> isClientOnly(String userId) async {
    final roles = await getUserRoles(userId);
    return roles.length == 1 && roles.first == 'cli';
  }

  // 🔥 NUEVO LOGIN CON CÓDIGO DE GYM
  Future<Map<String, dynamic>> loginWithGymCode(
    String gymCode,
    String email,
    String password,
  ) async {
    try {
      // 1. Validar código de gym
      final gymData = await _gymService.validateGymCode(gymCode);

      if (gymData == null) {
        return {
          'success': false,
          'message': 'Código de gimnasio inválido o inactivo',
        };
      }

      final gymId = gymData['gymId'] as String;
      final tenantId = gymData['tenantId'] as String;
      final gymName = gymData['gymName'] as String;

      // 2. Autenticar usuario
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return {'success': false, 'message': 'Error de autenticación'};
      }

      final userId = userCredential.user!.uid;

      // 3. Verificar que el usuario pertenece al gym
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      final userData = userDoc.data()!;
      final userGymId = userData['gymId'] as String?;

      // 🔥 VALIDACIÓN: Si el usuario no tiene gymId asignado
      if (userGymId == null || userGymId.isEmpty) {
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Tu cuenta no está asociada a ningún gimnasio. Por favor, contacta al administrador.',
        };
      }

      if (userGymId != gymId) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Este usuario no pertenece al gimnasio $gymName',
        };
      }

      // 4. Verificar si es cliente y validar membresía
      final rolesData = userData['roles'] as List<dynamic>?;
      final isClient =
          rolesData != null &&
          rolesData.length == 1 &&
          rolesData.first['id'] == 'cli';

      if (isClient) {
        final daysRemaining = await _subscriptionService
            .getDaysRemainingInSubscription(userId, gymId);

        if (daysRemaining < 1) {
          await _auth.signOut();
          return {
            'success': false,
            'message':
                'Su membresía ha vencido. Por favor, contacte a la secretaría para renovarla.',
            'requiresRenewal': true,
          };
        }

        if (daysRemaining <= 5) {
          return {
            'success': true,
            'gymId': gymId,
            'tenantId': tenantId,
            'gymName': gymName,
            'code': gymCode,
            'warning':
                'Su membresía vence en $daysRemaining día${daysRemaining == 1 ? '' : 's'}. Por favor renuévela pronto.',
          };
        }
      }

      return {
        'success': true,
        'gymId': gymId,
        'tenantId': tenantId,
        'gymName': gymName,
        'code': gymCode,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este correo electrónico';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada';
          break;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}',
      };
    }
  }

  // Iniciar sesión verificando membresía para clientes (DEPRECATED - usar loginWithGymCode)
  @Deprecated('Use loginWithGymCode instead')
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return {'success': false, 'message': 'Error de autenticación'};
      }

      // Verificar si es cliente
      final isClient = await isClientOnly(userCredential.user!.uid);
      if (isClient) {
        // NOTA: Este método no puede obtener gymId, debe migrar a loginWithGymCode
        // Se deja temporalmente para compatibilidad
        return {
          'success': false,
          'message': 'Use loginWithGymCode para iniciar sesión',
        };
      }

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este correo electrónico';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada';
          break;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}',
      };
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
