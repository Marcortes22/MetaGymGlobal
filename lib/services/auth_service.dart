import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import '../services/service_locator.dart';

class AuthService {
  late final FirebaseAuth _auth;
  late final SubscriptionService _subscriptionService;
  late final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    SubscriptionService? subscriptionService,
    FirebaseFirestore? firestore,
  }) {
    final serviceLocator = ServiceLocator();
    _auth = auth ??
            serviceLocator.getService<FirebaseAuth>() ??
            FirebaseAuth.instance;
    _subscriptionService = subscriptionService ??
                          serviceLocator.getService<SubscriptionService>() ??
                          SubscriptionService();
    _firestore = firestore ??
                 serviceLocator.getService<FirebaseFirestore>() ??
                 FirebaseFirestore.instance;
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

  // Verifica si un cliente puede acceder al sistema
  Future<Map<String, dynamic>> canClientAccess(String userId) async {
    final isClient = await isClientOnly(userId);
    if (!isClient) {
      return {'canAccess': true}; // No es cliente, puede acceder
    }

    // Verificar membresía activa
    final hasValidSubscription = await _subscriptionService.hasValidSubscription(userId);
    if (!hasValidSubscription) {
      return {
        'canAccess': false,
        'message': 'Su membresía ha expirado. Por favor renuévela para continuar.',
      };
    }

    // Obtener días restantes
    final daysRemaining = await _subscriptionService.getDaysRemainingInSubscription(userId);
    if (daysRemaining <= 5) {
      return {
        'canAccess': true,
        'warning': 'Su membresía vence en $daysRemaining día${daysRemaining == 1 ? '' : 's'}',
      };
    }

    return {'canAccess': true};
  }
  // Iniciar sesión verificando membresía para clientes
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
        return {
          'success': false,
          'message': 'Error de autenticación',
        };
      }

      // Verificar si es cliente
      final isClient = await isClientOnly(userCredential.user!.uid);
      if (isClient) {
        // Obtener días restantes de la membresía
        final daysRemaining = await _subscriptionService.getDaysRemainingInSubscription(userCredential.user!.uid);
        
        if (daysRemaining < 1) {
          await _auth.signOut(); // Cerrar sesión si no tiene acceso
          return {
            'success': false,
            'message': 'Su membresía ha vencido. Por favor, contacte a la secretaría para renovarla.',
            'requiresRenewal': true,
          };
        }
        
        // Si quedan pocos días, permitir acceso pero mostrar advertencia
        if (daysRemaining <= 5) {
          return {
            'success': true,
            'warning': 'Su membresía vence en $daysRemaining día${daysRemaining == 1 ? '' : 's'}. Por favor renuévela pronto.',
          };
        }
      }

      return {
        'success': true,
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
      return {
        'success': false,
        'message': message,
      };
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
