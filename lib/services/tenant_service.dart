import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant.dart';
import '../models/tenant_subscription.dart';

class TenantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener tenant por ID
  Future<Tenant?> getTenantById(String tenantId) async {
    try {
      final doc = await _firestore.collection('tenants').doc(tenantId).get();
      if (!doc.exists) return null;
      return Tenant.fromFirestore(doc);
    } catch (e) {
      print('Error obteniendo tenant: $e');
      return null;
    }
  }

  // Verificar si la suscripción del tenant está activa
  Future<bool> isSubscriptionActive(String tenantId) async {
    try {
      final tenant = await getTenantById(tenantId);
      if (tenant == null || !tenant.isActive) return false;

      // Verificar fecha de expiración
      return tenant.subscriptionEndDate.isAfter(DateTime.now());
    } catch (e) {
      print('Error verificando suscripción: $e');
      return false;
    }
  }

  // Obtener suscripción activa del tenant
  Future<TenantSubscription?> getActiveTenantSubscription(
    String tenantId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('tenant_subscriptions')
              .where('tenantId', isEqualTo: tenantId)
              .where('status', isEqualTo: 'active')
              .orderBy('endDate', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) return null;

      return TenantSubscription.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error obteniendo suscripción activa: $e');
      return null;
    }
  }

  // Obtener todas las suscripciones del tenant (historial)
  Future<List<TenantSubscription>> getTenantSubscriptions(
    String tenantId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('tenant_subscriptions')
              .where('tenantId', isEqualTo: tenantId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => TenantSubscription.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo suscripciones: $e');
      return [];
    }
  }

  // Crear nuevo tenant
  Future<String?> createTenant(Tenant tenant) async {
    try {
      final docRef = await _firestore.collection('tenants').add(tenant.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creando tenant: $e');
      return null;
    }
  }

  // Actualizar tenant
  Future<bool> updateTenant(String tenantId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('tenants').doc(tenantId).update(data);
      return true;
    } catch (e) {
      print('Error actualizando tenant: $e');
      return false;
    }
  }

  // Renovar suscripción
  Future<bool> renewSubscription(
    String tenantId,
    String planId,
    int durationDays,
    double amount,
  ) async {
    try {
      final tenant = await getTenantById(tenantId);
      if (tenant == null) return false;

      final now = DateTime.now();
      final newEndDate = now.add(Duration(days: durationDays));

      // Crear nueva suscripción
      await _firestore.collection('tenant_subscriptions').add({
        'tenantId': tenantId,
        'planId': planId,
        'status': 'active',
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(newEndDate),
        'paymentAmount': amount,
        'paymentDate': Timestamp.fromDate(now),
        'autoRenew': true,
        'createdAt': Timestamp.fromDate(now),
        'cancelledAt': null,
      });

      // Actualizar tenant
      await updateTenant(tenantId, {
        'currentPlanId': planId,
        'subscriptionEndDate': Timestamp.fromDate(newEndDate),
      });

      return true;
    } catch (e) {
      print('Error renovando suscripción: $e');
      return false;
    }
  }

  // Cancelar suscripción
  Future<bool> cancelSubscription(String tenantId) async {
    try {
      final subscription = await getActiveTenantSubscription(tenantId);
      if (subscription == null) return false;

      final now = DateTime.now();

      // Actualizar estado de la suscripción
      await _firestore
          .collection('tenant_subscriptions')
          .doc(subscription.id)
          .update({
            'status': 'cancelled',
            'cancelledAt': Timestamp.fromDate(now),
            'autoRenew': false,
          });

      // Desactivar tenant
      await updateTenant(tenantId, {'is_active': false});

      return true;
    } catch (e) {
      print('Error cancelando suscripción: $e');
      return false;
    }
  }

  // Verificar límites del plan (para validaciones)
  Future<Map<String, dynamic>?> getPlanLimits(String tenantId) async {
    try {
      final tenant = await getTenantById(tenantId);
      if (tenant == null) return null;

      final planDoc =
          await _firestore
              .collection('saas_plans')
              .doc(tenant.currentPlanId)
              .get();

      if (!planDoc.exists) return null;

      final planData = planDoc.data()!;
      return {
        'maxClients': planData['max_clients'],
        'maxGyms': planData['max_gyms'],
        'planName': planData['name'],
      };
    } catch (e) {
      print('Error obteniendo límites del plan: $e');
      return null;
    }
  }

  // Verificar si puede agregar más usuarios
  Future<bool> canAddMoreUsers(String gymId, String tenantId) async {
    try {
      // Obtener límites del plan
      final limits = await getPlanLimits(tenantId);
      if (limits == null) return false;

      final maxClients = limits['maxClients'] as int;

      // Contar usuarios actuales del gym
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('gymId', isEqualTo: gymId)
              .get();

      return usersSnapshot.docs.length < maxClients;
    } catch (e) {
      print('Error verificando límite de usuarios: $e');
      return false;
    }
  }

  // Generar código único para tenant
  Future<String> generateUniqueTenantCode(String companyName) async {
    try {
      String baseCode = companyName
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .toUpperCase()
          .substring(0, companyName.length >= 6 ? 6 : companyName.length);

      int counter = 1;
      String code = '$baseCode${counter.toString().padLeft(3, '0')}';

      while (true) {
        final exists =
            await _firestore
                .collection('tenants')
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
      print('Error generando código de tenant: $e');
      return 'TENANT001';
    }
  }
}
