import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

String generateRandomPin() {
  final random = Random();
  return (1000 + random.nextInt(9000)).toString();
}

// ═══════════════════════════════════════════════════════════════
// 📦 DATOS DE EJEMPLO ORGANIZADOS EN CONSTANTES
// ═══════════════════════════════════════════════════════════════

// --- SaaS Plans ---
const _saasPlansData = {
  'basic_plan': {
    'name': 'Plan Básico',
    'price': 29.99,
    'max_clients': 50,
    'max_gyms': 1,
    'description': 'Plan ideal para gimnasios pequeños',
    'features': [
      'Hasta 50 clientes',
      '1 gimnasio',
      'Gestión de membresías',
      'Check-in digital',
      'Soporte por email',
    ],
    'is_active': true,
    'platform_config_id': null,
  },
  'premium_plan': {
    'name': 'Plan Premium',
    'price': 79.99,
    'max_clients': 200,
    'max_gyms': 3,
    'description': 'Plan profesional para gimnasios en crecimiento',
    'features': [
      'Hasta 200 clientes',
      '3 gimnasios',
      'Rutinas personalizadas',
      'Reportes',
    ],
    'is_active': true,
    'platform_config_id': null,
  },
  'enterprise_plan': {
    'name': 'Plan Enterprise',
    'price': 199.99,
    'max_clients': 999999,
    'max_gyms': 999,
    'description': 'Plan completo para cadenas de gimnasios',
    'features': ['Clientes ilimitados', 'Gimnasios ilimitados', 'API'],
    'is_active': true,
    'platform_config_id': null,
  },
};

// --- Tenants ---
// Nota: se actualizó el tenant por defecto a un nombre más representativo
// y se cambió su identificador para evitar confusiones con ejemplos anteriores.
const _tenantsData = {
  'tenant_global_001': {
    'id': 'TENANTGLOBAL001',
    'is_active': true,
    'companyName': 'Fitness Global S.A.',
    'companyEmail': 'admin@fitnessglobal.com',
    'companyPhone': '555-0000',
    'ownerId': 'wNN46MrU3jXRV3y59Rkuh8CnTqH3', // Marco es el dueño
    'currentPlanId': 'premium_plan',
  },
};

// --- Tenant Subscriptions ---
const _tenantSubscriptionsData = {
  'sub_tenant_001': {
    'id': 'sub_tenant_001',
    'tenantId': 'tenant_global_001',
    'planId': 'premium_plan',
    'status': 'active',
    'paymentAmount': 79.99,
    'autoRenew': true,
    'cancelledAt': null,
  },
};

// --- Gyms ---
// Gym por defecto renombrado y con código más claro
const _gymsData = {
  'gym_global_001': {
    'tenantId': 'tenant_global_001',
    'name': 'Fitness Global Center',
    'code': 'FITGYM001',
    'email': 'contact@fitnessglobal.com',
    'phone': '555-1111',
    'address': 'Calle Principal 123',
    'city': 'San José',
    'country': 'Costa Rica',
    'is_active': true,
  },
};

// --- Register Requests ---
const _registerRequestsData = {
  'request_001': {
    'name': 'Adriana',
    'admin_name': 'Adriana',
    'admin_surname1': 'Elizondo',
    'admin_surname2': 'Morera',
    'admin_phone': '12345678',
    'email': 'carlos@gmail.com',
    'state': 'approved',
    'company_name': 'STEAM',
    'gym_name': 'MM Fit',
    'gym_address':
        '1K AL NORESTE Y 80 METROS AL NORTE DEL EBAIS DE MONTE TOMO, HONJANCHA, GTE',
    'gym_phone': '12345678',
    'requested_plan': 'premium_plan',
    'generatedToken': 'tenant_CN7WQPOZ',
    'reviewedBy': 'uJaeO6MRvLhhypdBPouCsZkbHy22',
  },
};

// --- SaaS Register Requests ---
const _saasRegisterRequestsData = {
  'saas_request_001': {
    'name': 'Juan',
    'admin_name': 'Juan',
    'admin_surname1': 'Pérez',
    'admin_surname2': 'López',
    'admin_phone': '555-8888',
    'email': 'juan@nuevogym.com',
    'state': 'pending',
    'company_name': 'Gimnasio Fitness Pro',
    'gym_name': 'Fitness Pro Centro',
    'gym_address': 'Av. Central 456',
    'gym_phone': '555-9999',
    'requested_plan': 'premium_plan',
  },
};

// --- Roles ---
const _rolesData = {
  'cli': {'name': 'Client', 'description': 'Role for regular gym users.'},
  'coa': {'name': 'Trainer', 'description': 'Role for trainers and coaches.'},
  'sec': {'name': 'Secretary', 'description': 'Role for secretaries.'},
  'own': {'name': 'Owner', 'description': 'Role for gym owners.'},
};

// --- Global Users ---
const _globalUsersData = {
  'uJaeO6MRvLhhypdBPouCsZkbHy22': {
    'email': 'brandoncarrilloalvarez2@gmail.com',
    'name': 'Brandon',
  },
};

// --- Users ---
// Usuarios actualizados:
// - Marco (wNN46MrU3jXRV3y59Rkuh8CnTqH3): Owner con todos los roles
// - Adriana (LempAa6wkMePDPc0v9CTHU3p7E32): Entrenadora (crea rutinas y clases)
// - Megan (EQdDQyw3oRgD6u8ZkH08fswkV5n1): Secretaria (gestiona clientes)
// - Lorenzo (aYgpWpY74UXG91O1sM2m075Hk9i2): Cliente con suscripción activa
final _usersData = {
  'wNN46MrU3jXRV3y59Rkuh8CnTqH3': {
    'gymId': 'gym_global_001',
    'tenantId': 'tenant_global_001',
    'user_id': '504420108',
    'name': 'Marco',
    'surname1': 'Cortés',
    'surname2': 'Castillo',
    'email': 'dueno@fitnessglobal.com',
    'phone': '555-1234',
    'pin': generateRandomPin(),
    'roles': [
      {'id': 'cli', 'name': 'Cliente'},
      {'id': 'own', 'name': 'Dueño'},
      {'id': 'sec', 'name': 'Secretario'},
      {'id': 'coa', 'name': 'Entrenador'},
    ],
    'height': 175,
    'weight': 72,
    'dateOfBirth': '1995-06-15',
    'profilePictureUrl': null,
  },
  'LempAa6wkMePDPc0v9CTHU3p7E32': {
    'gymId': 'gym_global_001',
    'tenantId': 'tenant_global_001',
    'user_id': '504420408',
    'name': 'Adriana',
    'surname1': 'Morera',
    'surname2': 'Elizondo',
    'email': 'adrianamorera126@gmail.com',
    'phone': '555-2345',
    'pin': generateRandomPin(),
    'roles': [
      {'id': 'coa', 'name': 'Entrenador'},
    ],
    'height': 165,
    'weight': 58,
    'dateOfBirth': '1992-03-20',
    'profilePictureUrl': null,
  },
  'EQdDQyw3oRgD6u8ZkH08fswkV5n1': {
    'gymId': 'gym_global_001',
    'tenantId': 'tenant_global_001',
    'user_id': '506420108',
    'name': 'Megan',
    'surname1': 'Soles',
    'surname2': 'Nuñez',
    'email': 'megansoles0@gmail.com',
    'phone': '555-3456',
    'pin': generateRandomPin(),
    'roles': [
      {'id': 'sec', 'name': 'Secretario'},
    ],
    'height': 160,
    'weight': 55,
    'dateOfBirth': '1998-07-10',
    'profilePictureUrl': null,
  },
  'aYgpWpY74UXG91O1sM2m075Hk9i2': {
    'gymId': 'gym_global_001',
    'tenantId': 'tenant_global_001',
    'user_id': '503420109',
    'name': 'Lorenzo',
    'surname1': 'Martinez',
    'surname2': 'Sanchez',
    'email': 'lorensamartinez0@gmail.com',
    'phone': '555-4567',
    'pin': generateRandomPin(),
    'roles': [
      {'id': 'cli', 'name': 'Cliente'},
    ],
    'membershipId': 'monthly_plan',
    'height': 178,
    'weight': 75,
    'dateOfBirth': '1996-11-05',
    'profilePictureUrl': null,
  },
};
// --- Subscriptions (solo para CLIENTES: Lorenzo) ---
const _subscriptionsData = {
  'sub_lorenzo': {
    'userId': 'aYgpWpY74UXG91O1sM2m075Hk9i2', // Lorenzo (cliente)
    'gymId': 'gym_global_001',
    'tenantId': 'tenant_global_001',
    'membershipId': 'monthly_plan',
    'status': 'active',
    'type': 'new',
    'paymentAmount': 30.0,
    'cancelledAt': null,
  },
};

// --- Attendances (solo para CLIENTES: Lorenzo) ---
const _attendancesData = {
  'attendance_lorenzo_001': {
    'userId': 'aYgpWpY74UXG91O1sM2m075Hk9i2', // Lorenzo
    'gymId': 'gym_global_001',
    'tenantId': 'tenant_global_001',
  },
};

// --- Memberships ---
const _membershipsData = {
  'day_plan': {
    'gymId': 'gym_global_001',
    'name': 'Plan Diario',
    'price': 10.0,
    'durationDays': 1,
    'description': 'Acceso por un día.',
  },
  'weekly_plan': {
    'gymId': 'gym_global_001',
    'name': 'Plan Semanal',
    'price': 15.0,
    'durationDays': 7,
    'description': 'Acceso por una semana.',
  },
  'monthly_plan': {
    'gymId': 'gym_global_001',
    'name': 'Plan Mensual',
    'price': 30.0,
    'durationDays': 30,
    'description': 'Acceso ilimitado durante 30 días.',
  },
  'annual_plan': {
    'gymId': 'gym_global_001',
    'name': 'Plan Anual',
    'price': 300.0,
    'durationDays': 365,
    'description': 'Acceso ilimitado durante todo el año.',
  },
};

// --- Muscle Groups ---
const _muscleGroupsData = {
  'muscle_chest': {'name': 'Pecho', 'description': 'Grupo muscular del pecho.'},
  'muscle_back': {
    'name': 'Espalda',
    'description': 'Grupo muscular de espalda.',
  },
  'muscle_legs': {
    'name': 'Piernas',
    'description': 'Grupo muscular de piernas.',
  },
  'muscle_arms': {'name': 'Brazos', 'description': 'Grupo muscular de brazos.'},
};

// --- Exercises (creados por la entrenadora Adriana) ---
const _exercisesData = {
  'ex_bench_press': {
    'gymId': 'gym_global_001',
    'name': 'Press de Banca',
    'muscleGroupId': 'muscle_chest',
    'equipment': 'Barra',
    'difficulty': 'Intermedio',
    'videoUrl': 'https://example.com/bench-press',
    'description': 'Ejercicio compuesto para pecho.',
  },
  'ex_pull_up': {
    'gymId': 'gym_global_001',
    'name': 'Dominadas',
    'muscleGroupId': 'muscle_back',
    'equipment': 'Peso Corporal',
    'difficulty': 'Avanzado',
    'videoUrl': 'https://example.com/pullup',
    'description': 'Ejercicio para fortalecer la espalda.',
  },
  'ex_squat': {
    'gymId': 'gym_global_001',
    'name': 'Sentadilla con Barra',
    'muscleGroupId': 'muscle_legs',
    'equipment': 'Barra',
    'difficulty': 'Intermedio',
    'videoUrl': 'https://example.com/squat',
    'description': 'Ejercicio compuesto para piernas.',
  },
  'ex_bicep_curl': {
    'gymId': 'gym_global_001',
    'name': 'Curl de Bíceps',
    'muscleGroupId': 'muscle_arms',
    'equipment': 'Mancuernas',
    'difficulty': 'Principiante',
    'videoUrl': 'https://example.com/curl',
    'description': 'Ejercicio de aislamiento para bíceps.',
  },
};

// --- Workouts (creados por la entrenadora Adriana) ---
const _workoutsData = {
  'workout_full_body': {
    'gymId': 'gym_global_001',
    'title': 'Rutina Full Body',
    'description': 'Rutina completa para todo el cuerpo.',
    'exercises': [
      {'exerciseId': 'ex_bench_press', 'repetitions': 12, 'sets': 4},
      {'exerciseId': 'ex_pull_up', 'repetitions': 8, 'sets': 3},
      {'exerciseId': 'ex_squat', 'repetitions': 10, 'sets': 4},
    ],
    'createdBy': 'LempAa6wkMePDPc0v9CTHU3p7E32', // Adriana (entrenadora)
    'level': 'Intermedio',
  },
  'workout_arms': {
    'gymId': 'gym_global_001',
    'title': 'Rutina de Brazos',
    'description': 'Rutina enfocada en brazos.',
    'exercises': [
      {'exerciseId': 'ex_bicep_curl', 'repetitions': 15, 'sets': 3},
      {'exerciseId': 'ex_pull_up', 'repetitions': 6, 'sets': 3},
    ],
    'createdBy': 'LempAa6wkMePDPc0v9CTHU3p7E32', // Adriana (entrenadora)
    'level': 'Principiante',
  },
};

// --- Assigned Workouts (Adriana asigna rutinas a su cliente Lorenzo) ---
const _assignedWorkoutsData = {
  'assigned_lorenzo_fullbody': {
    'gymId': 'gym_global_001',
    'userId': 'aYgpWpY74UXG91O1sM2m075Hk9i2', // Lorenzo (cliente)
    'workoutId': 'workout_full_body',
    'status': 'pending',
    'notes': 'Enfócate en la técnica.',
  },
};

// --- Progress (solo clientes que entrenan: Lorenzo) ---
const _progressData = {
  'progress_lorenzo_bench': {
    'gymId': 'gym_global_001',
    'userId': 'aYgpWpY74UXG91O1sM2m075Hk9i2', // Lorenzo
    'exerciseId': 'ex_bench_press',
    'setsCompleted': 4,
    'repetitionsAchieved': 12,
    'weightLiftedKg': 60.0,
    'bodyWeightKg': 75.0,
    'notes': 'Buena forma, sin dolor.',
  },
};

// --- Classes (creadas por la entrenadora Adriana) ---
const _classesData = {
  'class_spinning': {
    'gymId': 'gym_global_001',
    'name': 'Clase de Spinning',
    'instructorId': 'LempAa6wkMePDPc0v9CTHU3p7E32', // Adriana (entrenadora)
    'capacity': 15,
    'attendees': [
      'aYgpWpY74UXG91O1sM2m075Hk9i2', // Lorenzo
    ],
  },
  'class_yoga': {
    'gymId': 'gym_global_001',
    'name': 'Clase de Yoga',
    'instructorId': 'LempAa6wkMePDPc0v9CTHU3p7E32', // Adriana (entrenadora)
    'capacity': 20,
    'attendees': ['aYgpWpY74UXG91O1sM2m075Hk9i2'], // Lorenzo
  },
};

// --- Platform Config ---
const _platformConfigData = {
  'default_config': {
    'email': '',
    'name': '',
    'phone': '',
    'platform_plans': [
      {
        'description': '',
        'features': '',
        'max_clients': '',
        'name': '',
        'price': '',
      },
    ],
  },
};

// --- Subscription Payments (pagos de clientes) ---
const _subscriptionPaymentsData = {
  'payment_lorenzo_001': {
    'amount': 30.0,
    'hasPaid': true,
    'notes': '',
    'status': ['active'],
    'subscriptionId': 'sub_lorenzo',
    'tenantId': 'tenant_global_001',
  },
};

// ═══════════════════════════════════════════════════════════════
// 🔧 HELPERS PARA GESTIONAR COLECCIONES
// ═══════════════════════════════════════════════════════════════

/// Elimina todos los documentos de una colección
Future<void> _deleteCollection(
  FirebaseFirestore firestore,
  String collectionName,
) async {
  final snapshot = await firestore.collection(collectionName).get();
  for (final doc in snapshot.docs) {
    await doc.reference.delete();
  }
  print(
    '   🗑️  Colección "$collectionName" limpiada (${snapshot.docs.length} docs eliminados)',
  );
}

Future<void> _writeCollection(
  FirebaseFirestore firestore,
  String collectionName,
  Map<String, Map<String, dynamic>> docs, {
  bool addTimestamps = true,
}) async {
  for (final entry in docs.entries) {
    final id = entry.key;
    final data = Map<String, dynamic>.from(entry.value);

    // Agregar timestamps si no existen
    if (addTimestamps) {
      final now = DateTime.now();
      if (!data.containsKey('createdAt')) data['createdAt'] = now;

      // Campos especiales con fechas
      if (collectionName == 'tenant_subscriptions') {
        if (!data.containsKey('startDate')) data['startDate'] = now;
        if (!data.containsKey('endDate')) {
          data['endDate'] = now.add(const Duration(days: 30));
        }
        if (!data.containsKey('paymentDate')) data['paymentDate'] = now;
      }

      if (collectionName == 'subscriptions') {
        if (!data.containsKey('startDate')) data['startDate'] = now;
        if (!data.containsKey('endDate')) {
          data['endDate'] = now.add(const Duration(days: 30));
        }
        if (!data.containsKey('paymentDate')) data['paymentDate'] = now;
      }

      if (collectionName == 'tenants') {
        if (!data.containsKey('subscriptionEndDate')) {
          data['subscriptionEndDate'] = now.add(const Duration(days: 30));
        }
      }

      if (collectionName == 'attendances') {
        if (!data.containsKey('date')) data['date'] = now;
        if (!data.containsKey('checkInTime')) data['checkInTime'] = now;
        if (!data.containsKey('checkOutTime')) {
          data['checkOutTime'] = now.add(const Duration(hours: 2));
        }
      }

      if (collectionName == 'assigned_workouts') {
        if (!data.containsKey('assignedAt')) data['assignedAt'] = now;
      }

      if (collectionName == 'progress') {
        if (!data.containsKey('date')) data['date'] = now;
      }

      if (collectionName == 'classes') {
        if (!data.containsKey('startDateTime')) {
          data['startDateTime'] = now.add(const Duration(days: 3, hours: 18));
        }
        if (!data.containsKey('endDateTime')) {
          data['endDateTime'] = now.add(const Duration(days: 3, hours: 19));
        }
      }

      if (collectionName == 'subscription_payments') {
        if (!data.containsKey('paidAt')) data['paidAt'] = now;
        if (!data.containsKey('periodStart')) data['periodStart'] = now;
        if (!data.containsKey('periodEnd')) {
          data['periodEnd'] = now.add(const Duration(days: 30));
        }
      }

      if (collectionName == 'register_requests') {
        if (!data.containsKey('date')) data['date'] = now;
        if (!data.containsKey('reviewedAt')) data['reviewedAt'] = now;
      }

      if (collectionName == 'saas_register_requests') {
        if (!data.containsKey('date')) data['date'] = now;
      }
    }

    await firestore.collection(collectionName).doc(id).set(data);
  }
}

// ═══════════════════════════════════════════════════════════════
// 🚀 FUNCIÓN PRINCIPAL
// ═══════════════════════════════════════════════════════════════

Future<void> createFakeGymData() async {
  final firestore = FirebaseFirestore.instance;

  print('📦 Iniciando proceso de creación de datos en Firestore...');
  print('');
  print('🗑️  PASO 1: Limpiando colecciones existentes...');

  // Eliminar todas las colecciones en orden inverso (para respetar FKs)
  await _deleteCollection(firestore, 'subscription_payments');
  await _deleteCollection(firestore, 'platform_config');
  await _deleteCollection(firestore, 'saas_register_requests');
  await _deleteCollection(firestore, 'register_requests');
  await _deleteCollection(firestore, 'classes');
  await _deleteCollection(firestore, 'progress');
  await _deleteCollection(firestore, 'assigned_workouts');
  await _deleteCollection(firestore, 'workouts');
  await _deleteCollection(firestore, 'exercises');
  await _deleteCollection(firestore, 'muscle_groups');
  await _deleteCollection(firestore, 'attendances');
  await _deleteCollection(firestore, 'subscriptions');
  await _deleteCollection(firestore, 'memberships');
  await _deleteCollection(firestore, 'users');
  await _deleteCollection(firestore, 'global_users');
  await _deleteCollection(firestore, 'roles');
  await _deleteCollection(firestore, 'gyms');
  await _deleteCollection(firestore, 'tenant_subscriptions');
  await _deleteCollection(firestore, 'tenants');
  await _deleteCollection(firestore, 'saas_plans');

  print('');
  print('✅ Todas las colecciones han sido limpiadas.');
  print('');
  print('📝 PASO 2: Creando nuevos datos...');

  // Escribir cada colección en orden lógico (respetando FKs)
  await _writeCollection(firestore, 'saas_plans', _saasPlansData);
  await _writeCollection(firestore, 'tenants', _tenantsData);
  await _writeCollection(
    firestore,
    'tenant_subscriptions',
    _tenantSubscriptionsData,
  );
  await _writeCollection(firestore, 'gyms', _gymsData);
  await _writeCollection(firestore, 'roles', _rolesData);
  await _writeCollection(firestore, 'global_users', _globalUsersData);
  await _writeCollection(firestore, 'users', _usersData);
  await _writeCollection(firestore, 'memberships', _membershipsData);
  await _writeCollection(firestore, 'subscriptions', _subscriptionsData);
  await _writeCollection(firestore, 'attendances', _attendancesData);
  await _writeCollection(firestore, 'muscle_groups', _muscleGroupsData);
  await _writeCollection(firestore, 'exercises', _exercisesData);
  await _writeCollection(firestore, 'workouts', _workoutsData);
  await _writeCollection(firestore, 'assigned_workouts', _assignedWorkoutsData);
  await _writeCollection(firestore, 'progress', _progressData);
  await _writeCollection(firestore, 'classes', _classesData);
  await _writeCollection(firestore, 'register_requests', _registerRequestsData);
  await _writeCollection(
    firestore,
    'saas_register_requests',
    _saasRegisterRequestsData,
  );
  await _writeCollection(firestore, 'platform_config', _platformConfigData);
  await _writeCollection(
    firestore,
    'subscription_payments',
    _subscriptionPaymentsData,
  );

  print('✅ Datos de ejemplo creados exitosamente en Firestore.');
  print('');
  print('👥 Usuarios creados:');
  print('   • Marco (Owner) - Todos los roles');
  print('   • Adriana (Entrenadora) - Crea rutinas y clases');
  print('   • Megan (Secretaria) - Gestiona clientes');
  print('   • Lorenzo (Cliente) - Tiene suscripción activa');
  print('');
  print('🏋️ Datos relacionados:');
  print('   • 1 Suscripción (Lorenzo)');
  print('   • 1 Rutina asignada (Adriana → Lorenzo)');
  print('   • 2 Clases (Adriana como instructora)');
  print('   • 1 Registro de progreso (Lorenzo)');
  print('   • 1 Asistencia (Lorenzo)');
}
