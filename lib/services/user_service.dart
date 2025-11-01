import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../services/service_locator.dart';

/// Servicio para manejar todas las operaciones CRUD de usuarios
class UserService {
  late final CollectionReference<Map<String, dynamic>> _collection;
  late final auth.FirebaseAuth _auth;

  // Constructor with optional dependency injection
  UserService({FirebaseFirestore? firestore, auth.FirebaseAuth? firebaseAuth}) {
    final serviceLocator = ServiceLocator();

    final firestoreInstance =
        firestore ??
        serviceLocator.getService<FirebaseFirestore>() ??
        FirebaseFirestore.instance;

    _collection = firestoreInstance.collection('users');

    _auth =
        firebaseAuth ??
        serviceLocator.getService<auth.FirebaseAuth>() ??
        auth.FirebaseAuth.instance;
  }

  /// Crea un nuevo usuario con autenticación y datos en Firestore
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required List<Map<String, String>> roles,
    String? surname1,
    String? surname2,
    String? phone,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = authResult.user!.uid;

      // Crear documento de usuario en Firestore
      final user = User(
        id: userId,
        userId: userId,
        name: name,
        surname1: surname1 ?? '',
        surname2: surname2 ?? '',
        email: email,
        phone: phone ?? '',
        roles: roles,
        height: 0,
        weight: 0,
        dateOfBirth: '',
      );

      await _collection.doc(userId).set(user.toMap());
    } on auth.FirebaseAuthException catch (e) {
      print('Error creating user: ${e.message}');
      rethrow;
    }
  }

  /// Obtiene un usuario por su ID
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return User.fromMap(doc.id, doc.data()!);
    } on FirebaseException {
      return null;
    }
  }

  /// Obtiene solo el nombre de un usuario por su ID
  Future<String?> getUserName(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  /// Obtiene todos los usuarios
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.id, doc.data()))
          .toList();
    } on FirebaseException {
      return [];
    }
  }

  /// Actualiza los datos de un usuario
  Future<void> updateUser(User user) async {
    try {
      await _collection.doc(user.id).update(user.toMap());
    } on FirebaseException catch (e) {
      print('Error updating user: ${e.message}');
      rethrow;
    }
  }

  /// Actualiza los roles de un usuario
  Future<void> updateUserRoles(
    String userId,
    List<Map<String, String>> roles,
  ) async {
    try {
      await _collection.doc(userId).update({'roles': roles});
    } on FirebaseException catch (e) {
      print('Error updating user roles: ${e.message}');
      rethrow;
    }
  }

  /// Elimina un usuario (tanto de Auth como de Firestore)
  Future<void> deleteUser(String id) async {
    try {
      // Eliminar de Firebase Auth si es el usuario actual
      final currentUser = await _auth.currentUser;
      if (currentUser?.uid == id) {
        await currentUser?.delete();
      }
      // Eliminar de Firestore
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      print('Error deleting user: ${e.message}');
      rethrow;
    }
  }

  /// Obtiene el nombre mostrable de un rol
  String _getRoleName(String roleId) {
    switch (roleId) {
      case 'own':
        return 'Administrador';
      case 'coa':
        return 'Entrenador';
      case 'sec':
        return 'Secretaria';
      case 'cli':
        return 'Cliente';
      default:
        return 'Usuario';
    }
  }

  /// Gets Firebase Auth current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get full user details including membership and subscription info
  Future<Map<String, dynamic>> getUserFullDetails(String userId) async {
    try {
      // Get basic user info
      final userDoc = await _collection.doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return {'error': 'Usuario no encontrado'};
      }

      final userData = userDoc.data()!;

      // Get membership info if available
      String? membershipName;
      if (userData['membershipId'] != null) {
        final membershipDoc =
            await FirebaseFirestore.instance
                .collection('memberships')
                .doc(userData['membershipId'])
                .get();

        if (membershipDoc.exists) {
          membershipName = membershipDoc.data()?['name'];
        }
      }

      // Get subscription info
      DocumentSnapshot? activeSubscription;
      final subscriptionQuery =
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .orderBy('endDate', descending: true)
              .limit(1)
              .get();

      if (subscriptionQuery.docs.isNotEmpty) {
        activeSubscription = subscriptionQuery.docs.first;
      }

      // Format the roles for display
      List<Map<String, dynamic>> userRoles = [];
      if (userData['roles'] != null) {
        userRoles = List<Map<String, dynamic>>.from(userData['roles']);
      }

      // Calculate user's age from date of birth
      int age = 0;
      if (userData['dateOfBirth'] != null &&
          userData['dateOfBirth'] is String) {
        final dob = DateTime.tryParse(userData['dateOfBirth']);
        if (dob != null) {
          final today = DateTime.now();
          age = today.year - dob.year;
          if (today.month < dob.month ||
              (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
        }
      }

      // Build result map with all user data
      return {
        'id': userId,
        'userData': userData,
        'membershipName': membershipName,
        'subscription': activeSubscription?.data(),
        'roles': userRoles,
        'age': age,
      };
    } catch (e) {
      print('Error getting user details: $e');
      return {'error': 'Error al obtener información del usuario: $e'};
    }
  }
}
