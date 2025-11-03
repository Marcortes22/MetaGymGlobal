import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym.dart';

class GymService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validar código de gimnasio (para login inicial)
  Future<Map<String, dynamic>?> validateGymCode(String code) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('gyms')
              .where('code', isEqualTo: code.toUpperCase())
              .where('is_active', isEqualTo: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // Código inválido
      }

      final gymDoc = querySnapshot.docs.first;
      final gymData = gymDoc.data();
      final tenantId = gymData['tenantId'];

      // Verificar que el tenant esté activo
      final tenantDoc =
          await _firestore.collection('tenants').doc(tenantId).get();

      if (!tenantDoc.exists || !tenantDoc.data()!['is_active']) {
        return null; // Tenant inactivo
      }

      // Verificar que la suscripción no esté expirada
      final subscriptionEndDate =
          (tenantDoc.data()!['subscriptionEndDate'] as Timestamp).toDate();
      if (subscriptionEndDate.isBefore(DateTime.now())) {
        return null; // Suscripción expirada
      }

      return {
        'gymId': gymDoc.id,
        'gymName': gymData['name'],
        'tenantId': tenantId,
        'code': gymData['code'],
      };
    } catch (e) {
      print('Error validando código de gym: $e');
      return null;
    }
  }

  // Obtener gimnasio por ID
  Future<Gym?> getGymById(String gymId) async {
    try {
      final doc = await _firestore.collection('gyms').doc(gymId).get();
      if (!doc.exists) return null;
      return Gym.fromFirestore(doc);
    } catch (e) {
      print('Error obteniendo gym: $e');
      return null;
    }
  }

  // Obtener todos los gyms de un tenant (para futuro multi-gym)
  Future<List<Gym>> getGymsByTenant(String tenantId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('gyms')
              .where('tenantId', isEqualTo: tenantId)
              .where('is_active', isEqualTo: true)
              .get();

      return querySnapshot.docs.map((doc) => Gym.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error obteniendo gyms del tenant: $e');
      return [];
    }
  }

  // Crear nuevo gimnasio
  Future<String?> createGym(Gym gym) async {
    try {
      final docRef = await _firestore.collection('gyms').add(gym.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creando gym: $e');
      return null;
    }
  }

  // Actualizar gimnasio
  Future<bool> updateGym(String gymId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('gyms').doc(gymId).update(data);
      return true;
    } catch (e) {
      print('Error actualizando gym: $e');
      return false;
    }
  }

  // Desactivar gimnasio
  Future<bool> deactivateGym(String gymId) async {
    try {
      await _firestore.collection('gyms').doc(gymId).update({
        'is_active': false,
      });
      return true;
    } catch (e) {
      print('Error desactivando gym: $e');
      return false;
    }
  }

  // Generar código único para nuevo gym
  Future<String> generateUniqueCode(String gymName) async {
    try {
      // Tomar las primeras letras del nombre
      String baseCode = gymName
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .toUpperCase()
          .substring(0, gymName.length >= 4 ? 4 : gymName.length);

      int counter = 1;
      String code = '$baseCode${counter.toString().padLeft(3, '0')}';

      // Verificar que no exista
      while (true) {
        final exists =
            await _firestore
                .collection('gyms')
                .where('code', isEqualTo: code)
                .limit(1)
                .get();

        if (exists.docs.isEmpty) {
          return code;
        }

        counter++;
        code = '$baseCode${counter.toString().padLeft(3, '0')}';
      }
    } catch (e) {
      print('Error generando código: $e');
      return 'GYM001';
    }
  }
}
