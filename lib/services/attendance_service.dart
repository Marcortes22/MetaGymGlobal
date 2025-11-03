import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import '../services/subscription_service.dart';
import '../services/service_locator.dart';

class AttendanceService {
  late final CollectionReference _collection;
  late final SubscriptionService _subscriptionService;

  // Constructor with optional dependency injection
  AttendanceService({
    FirebaseFirestore? firestore,
    SubscriptionService? subscriptionService,
  }) {
    final serviceLocator = ServiceLocator();

    final firestoreInstance =
        firestore ??
        serviceLocator.getService<FirebaseFirestore>() ??
        FirebaseFirestore.instance;

    _collection = firestoreInstance.collection('attendances');

    _subscriptionService =
        subscriptionService ??
        serviceLocator.getService<SubscriptionService>() ??
        SubscriptionService();
  }

  // 🔥 ACTUALIZADO - Registrar asistencia con gymId y tenantId
  Future<void> register(Attendance attendance) async {
    await _collection.add(attendance.toMap());
  }

  // 🔥 ACTUALIZADO - Obtener asistencias por usuario Y gym
  Future<List<Attendance>> getByUser(String userId, String gymId) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId)
            .get();
    return snapshot.docs
        .map(
          (doc) =>
              Attendance.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  /// 🔥 ACTUALIZADO - Check if user has already checked in today (en este gym)
  Future<bool> hasCheckedInToday(String userId, String gymId) async {
    // Get start and end of today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Query for attendance records for this user today in this gym
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId) // 🔥 NUEVO
            .where('date', isGreaterThanOrEqualTo: startOfDay)
            .where('date', isLessThanOrEqualTo: endOfDay)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  // Check if user has admin roles (coa, own, sec)
  Future<bool> hasAdminRole(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return false;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final roles = List<Map<String, dynamic>>.from(userData['roles'] ?? []);

    // Check if user has any admin role
    for (var role in roles) {
      final roleId = role['id'] as String;
      if (roleId == 'coa' || roleId == 'own' || roleId == 'sec') {
        return true;
      }
    }

    return false;
  }

  // Check if user is only a client (cli role only)
  Future<bool> isClientOnly(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return false;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final roles = List<Map<String, dynamic>>.from(userData['roles'] ?? []);

    if (roles.isEmpty) {
      return false;
    }

    // Check if user has only client role
    bool hasClientRole = false;
    for (var role in roles) {
      final roleId = role['id'] as String;
      if (roleId != 'cli') {
        return false; // Has some other role
      } else {
        hasClientRole = true;
      }
    }

    return hasClientRole; // Only has client role
  }

  // 🔥 ACTUALIZADO - Get subscription status info (con gymId)
  Future<Map<String, dynamic>> getSubscriptionInfo(
    String userId,
    String gymId,
  ) async {
    final hasValidSubscription = await _subscriptionService
        .hasValidSubscription(userId, gymId); // 🔥 ACTUALIZADO
    final daysRemaining = await _subscriptionService
        .getDaysRemainingInSubscription(userId, gymId); // 🔥 ACTUALIZADO

    return {'isValid': hasValidSubscription, 'daysRemaining': daysRemaining};
  }

  // 🔥 ACTUALIZADO - Check-in with PIN code (con gymId y tenantId)
  Future<Map<String, dynamic>> checkInWithPin(
    String pin,
    String gymId,
    String tenantId,
    Function(String) showMessage,
  ) async {
    try {
      // Find user with this PIN in this gym
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('pin', isEqualTo: pin)
              .where('gymId', isEqualTo: gymId) // 🔥 NUEVO
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        return {'success': false, 'message': 'PIN no válido'};
      }

      final userId = userQuery.docs.first.id;

      // Check if user already checked in today
      if (await hasCheckedInToday(userId, gymId)) {
        // 🔥 ACTUALIZADO
        showMessage("Ya registraste tu asistencia hoy.");
        return {
          'success': false,
          'message': 'Ya registraste tu asistencia hoy',
        };
      }
      // Check if the error is due to already checked in today

      // Check if user is client-only or has admin roles
      final isClientOnly = await this.isClientOnly(userId);

      if (isClientOnly) {
        // Client needs to have a valid subscription
        final subscriptionInfo = await getSubscriptionInfo(
          userId,
          gymId,
        ); // 🔥 ACTUALIZADO

        if (!subscriptionInfo['isValid']) {
          showMessage(
            "Su suscripción ha expirado. Por favor renueve su membresía.",
          );
          return {
            'success': false,
            'message':
                'Su suscripción ha expirado. Por favor renueve su membresía.',
          };
        }

        // Check if subscription is about to expire
        final daysRemaining = subscriptionInfo['daysRemaining'];
        if (daysRemaining <= 5) {
          // Register attendance but warn about expiration
          final attendance = Attendance(
            id: '',
            gymId: gymId, // 🔥 NUEVO
            tenantId: tenantId, // 🔥 NUEVO
            userId: userId,
            date: DateTime.now(),
            checkInTime: DateTime.now(),
          );

          await register(attendance);

          return {
            'success': true,
            'userId': userId,
            'warning':
                'Su suscripción vence en $daysRemaining día${daysRemaining == 1 ? '' : 's'}',
          };
        }
      }

      // Register attendance for admin users or clients with valid subscriptions
      final attendance = Attendance(
        id: '',
        gymId: gymId, // 🔥 NUEVO
        tenantId: tenantId, // 🔥 NUEVO
        userId: userId,
        date: DateTime.now(),
        checkInTime: DateTime.now(),
      );

      await register(attendance);
      return {'success': true, 'userId': userId};
    } catch (e) {
      print('Error checking in with PIN: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// 🔥 ACTUALIZADO - Check-in with QR code (con gymId y tenantId)
  Future<Map<String, dynamic>> checkInWithQR(
    String qrData,
    String gymId,
    String tenantId,
  ) async {
    try {
      // Find user with this QR data in this gym
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('qrCode', isEqualTo: qrData)
              .where('gymId', isEqualTo: gymId) // 🔥 NUEVO
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        return {'success': false, 'message': 'QR no válido'};
      }

      final userId = userQuery.docs.first.id;

      // Check if user already checked in today
      if (await hasCheckedInToday(userId, gymId)) {
        // 🔥 ACTUALIZADO
        return {
          'success': false,
          'message': 'Ya registraste tu asistencia hoy',
        };
      }

      // Check if user is client-only or has admin roles
      final isClientOnly = await this.isClientOnly(userId);

      if (isClientOnly) {
        // Client needs to have a valid subscription
        final subscriptionInfo = await getSubscriptionInfo(
          userId,
          gymId,
        ); // 🔥 ACTUALIZADO

        if (!subscriptionInfo['isValid']) {
          return {
            'success': false,
            'message':
                'Su suscripción ha expirado. Por favor renueve su membresía.',
          };
        }

        // Check if subscription is about to expire
        final daysRemaining = subscriptionInfo['daysRemaining'];
        if (daysRemaining <= 5) {
          // Register attendance but warn about expiration
          final attendance = Attendance(
            id: '',
            gymId: gymId, // 🔥 NUEVO
            tenantId: tenantId, // 🔥 NUEVO
            userId: userId,
            date: DateTime.now(),
            checkInTime: DateTime.now(),
          );

          await register(attendance);

          return {
            'success': true,
            'userId': userId,
            'warning':
                'Su suscripción vence en $daysRemaining día${daysRemaining == 1 ? '' : 's'}',
          };
        }
      }

      // Register attendance for admin users or clients with valid subscriptions
      final attendance = Attendance(
        id: '',
        gymId: gymId, // 🔥 NUEVO
        tenantId: tenantId, // 🔥 NUEVO
        userId: userId,
        date: DateTime.now(),
        checkInTime: DateTime.now(),
      );

      await register(attendance);
      return {'success': true, 'userId': userId};
    } catch (e) {
      print('Error in checkInWithQR: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get user's attendance history with optional filters
  Future<List<Map<String, dynamic>>> getUserAttendanceHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      Query query = _collection.where('userId', isEqualTo: userId);

      // Apply date filters if provided
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      // Order by date descending (newest first) and apply limit
      final snapshot =
          await query.orderBy('date', descending: true).limit(limit).get();

      // Transform data for display
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final checkInTime = (data['checkInTime'] as Timestamp).toDate();
        DateTime? checkOutTime;

        if (data['checkOutTime'] != null) {
          checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
        }

        // Calculate duration if check-out exists
        String duration = "N/A";
        if (checkOutTime != null) {
          final durationMinutes =
              checkOutTime.difference(checkInTime).inMinutes;
          duration = "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";
        }

        return {
          'id': doc.id,
          'date': date,
          'formattedDate': "${date.day}/${date.month}/${date.year}",
          'checkInTime': checkInTime,
          'formattedCheckInTime':
              "${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}",
          'checkOutTime': checkOutTime,
          'formattedCheckOutTime':
              checkOutTime != null
                  ? "${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}"
                  : "N/A",
          'duration': duration,
          'weekday': _getWeekdayName(date.weekday),
        };
      }).toList();
    } catch (e) {
      print('Error fetching attendance history: $e');
      return [];
    }
  }

  /// Check if user has an ongoing session (checked in but not checked out yet today)
  Future<Map<String, dynamic>> hasOngoingSession(
    String userId,
    String gymId,
  ) async {
    // Get start and end of today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Query for attendance records for this user today in this gym
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId) // 🔥 AGREGADO
            .where('date', isGreaterThanOrEqualTo: startOfDay)
            .where('date', isLessThanOrEqualTo: endOfDay)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return {'hasOngoing': false};
    }

    final attendanceData = snapshot.docs.first.data() as Map<String, dynamic>;
    final String attendanceId = snapshot.docs.first.id;

    // If checkOutTime is null, user has an ongoing session
    if (attendanceData['checkOutTime'] == null) {
      return {
        'hasOngoing': true,
        'attendanceId': attendanceId,
        'checkInTime': attendanceData['checkInTime'],
      };
    }

    return {'hasOngoing': false};
  }

  /// Process a user check-out
  Future<Map<String, dynamic>> checkOut(
    String userId,
    String gymId, // 🔥 AGREGADO
    Function(String) showMessage,
  ) async {
    try {
      // First, check if the user has an ongoing session
      final ongoingSession = await hasOngoingSession(
        userId,
        gymId,
      ); // 🔥 ACTUALIZADO

      if (!ongoingSession['hasOngoing']) {
        showMessage("No hay una sesión activa para registrar la salida");
        return {
          'success': false,
          'message': 'No hay una sesión activa para registrar la salida',
        };
      }

      final String? attendanceId = ongoingSession['attendanceId'] as String?;
      if (attendanceId == null) {
        showMessage('Error: No se encontró el ID de asistencia');
        return {
          'success': false,
          'message': 'Error: No se encontró el ID de asistencia',
        };
      }

      final checkInTime = (ongoingSession['checkInTime'] as Timestamp).toDate();

      final checkOutTime = DateTime.now();

      // Calculate session duration
      final durationMinutes = checkOutTime.difference(checkInTime).inMinutes;

      // Update the attendance record with check-out time
      await _collection.doc(attendanceId).update({
        'checkOutTime': checkOutTime,
      });

      showMessage(
        'Salida registrada exitosamente, Tiempo: "${durationMinutes ~/ 60}h ${durationMinutes % 60}m"',
      );

      return {
        'success': true,
        'message': 'Salida registrada exitosamente',
        'duration': "${durationMinutes ~/ 60}h ${durationMinutes % 60}m",
        'checkOutTime': checkOutTime,
      };
    } catch (e) {
      print('Error during check-out: $e');
      showMessage('Error al registrar la salida: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error al registrar la salida: ${e.toString()}',
      };
    }
  }

  /// Process a check-out using PIN code
  Future<Map<String, dynamic>> checkOutWithPin(
    String pin,
    Function(String) showMessage,
  ) async {
    try {
      // Find user with this PIN
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('pin', isEqualTo: pin)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        showMessage('PIN no válido');
        return {'success': false, 'message': 'PIN no válido'};
      }

      final userId = userQuery.docs.first.id;
      final userData = userQuery.docs.first.data();
      final gymId = userData['gymId'] ?? ''; // 🔥 AGREGADO

      // Process the check-out
      return await checkOut(userId, gymId, showMessage); // 🔥 ACTUALIZADO
    } catch (e) {
      print('Error checking out with PIN: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Helper method to get weekday name in Spanish
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Lunes";
      case 2:
        return "Martes";
      case 3:
        return "Miércoles";
      case 4:
        return "Jueves";
      case 5:
        return "Viernes";
      case 6:
        return "Sábado";
      case 7:
        return "Domingo";
      default:
        return "";
    }
  }
}
