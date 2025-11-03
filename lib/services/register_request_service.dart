import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/register_request.dart';
import '../models/tenant.dart';
import '../models/gym.dart';
import 'tenant_service.dart';
import 'gym_service.dart';

class RegisterRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TenantService _tenantService = TenantService();
  final GymService _gymService = GymService();

  // Obtener todas las solicitudes pendientes
  Future<List<RegisterRequest>> getPendingRequests() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('saas_register_request')
              .where('state', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => RegisterRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo solicitudes pendientes: $e');
      return [];
    }
  }

  // Obtener todas las solicitudes
  Future<List<RegisterRequest>> getAllRequests() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('saas_register_request')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => RegisterRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo solicitudes: $e');
      return [];
    }
  }

  // Crear nueva solicitud de registro
  Future<String?> createRegisterRequest(RegisterRequest request) async {
    try {
      final docRef = await _firestore
          .collection('saas_register_request')
          .add(request.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creando solicitud: $e');
      return null;
    }
  }

  // Aprobar solicitud (crear tenant + gym + usuario admin)
  Future<bool> approveRequest(String requestId) async {
    try {
      // Obtener solicitud
      final requestDoc =
          await _firestore
              .collection('saas_register_request')
              .doc(requestId)
              .get();

      if (!requestDoc.exists) return false;

      final request = RegisterRequest.fromFirestore(requestDoc);

      // 1. Crear Tenant
      final tenantCode = await _tenantService.generateUniqueTenantCode(
        request.companyName,
      );
      final tenant = Tenant(
        id: '',
        code: tenantCode,
        isActive: true,
        createdAt: DateTime.now(),
        companyName: request.companyName,
        companyEmail: request.email,
        companyPhone: request.gymPhone,
        ownerId: '', // Se actualizará después de crear el usuario
        currentPlanId: request.requestedPlan,
        subscriptionEndDate: DateTime.now().add(
          Duration(days: 30),
        ), // 30 días de prueba
      );

      final tenantId = await _tenantService.createTenant(tenant);
      if (tenantId == null) return false;

      // 2. Crear Gym
      final code = await _gymService.generateUniqueCode(request.gymName);
      final gym = Gym(
        id: '',
        tenantId: tenantId,
        name: request.gymName,
        code: code,
        email: request.email,
        phone: request.gymPhone,
        address: request.gymAddress,
        city: '',
        country: '',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final gymId = await _gymService.createGym(gym);
      if (gymId == null) return false;

      // 3. Crear suscripción inicial (30 días trial)
      await _firestore.collection('tenant_subscriptions').add({
        'tenantId': tenantId,
        'planId': request.requestedPlan,
        'status': 'trial',
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'paymentAmount': 0.0,
        'paymentDate': Timestamp.fromDate(DateTime.now()),
        'autoRenew': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'cancelledAt': null,
      });

      // 4. Actualizar estado de la solicitud
      await _firestore
          .collection('saas_register_request')
          .doc(requestId)
          .update({'state': 'approved'});

      return true;
    } catch (e) {
      print('Error aprobando solicitud: $e');
      return false;
    }
  }

  // Rechazar solicitud
  Future<bool> rejectRequest(String requestId, String reason) async {
    try {
      await _firestore
          .collection('saas_register_request')
          .doc(requestId)
          .update({'state': 'rejected', 'rejectionReason': reason});
      return true;
    } catch (e) {
      print('Error rechazando solicitud: $e');
      return false;
    }
  }

  // Obtener solicitud por ID
  Future<RegisterRequest?> getRequestById(String requestId) async {
    try {
      final doc =
          await _firestore
              .collection('saas_register_request')
              .doc(requestId)
              .get();

      if (!doc.exists) return null;
      return RegisterRequest.fromFirestore(doc);
    } catch (e) {
      print('Error obteniendo solicitud: $e');
      return null;
    }
  }
}
