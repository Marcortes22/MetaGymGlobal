import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';

/// Servicio para manejar los roles y la visualización de usuarios por roles
class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene todos los roles disponibles en el sistema
  Future<List<Role>> getAllRoles() async {
    try {
      final snapshot = await _db.collection('roles').get();
      return snapshot.docs
          .map((doc) => Role.fromMap(doc.id, doc.data()))
          .toList();
    } on FirebaseException {
      return [];
    }
  }

  /// Obtiene los usuarios agrupados por rol para visualización (filtrado por gym)
  Future<List<Map<String, dynamic>>> getUsersByRole(String gymId) async {
    final Map<String, List<Map<String, dynamic>>> usersByRole = {
      'own': [],
      'coa': [],
      'sec': [],
      'cli': [],
    };

    try {
      final QuerySnapshot<Map<String, dynamic>> usersSnapshot =
          await _db.collection('users').where('gymId', isEqualTo: gymId).get();

      _processUsers(usersSnapshot.docs, usersByRole);
      _sortUsersByName(usersByRole);

      return [
        {
          'role': 'own',
          'name': 'Administradores',
          'users': usersByRole['own']!,
        },
        {'role': 'coa', 'name': 'Entrenadores', 'users': usersByRole['coa']!},
        {'role': 'sec', 'name': 'Secretarias', 'users': usersByRole['sec']!},
        {'role': 'cli', 'name': 'Clientes', 'users': usersByRole['cli']!},
      ];
    } on FirebaseException {
      return [];
    }
  }

  /// Procesa la lista de usuarios y los agrupa por rol
  void _processUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, List<Map<String, dynamic>>> usersByRole,
  ) {
    for (final doc in docs) {
      final Map<String, dynamic> userData = doc.data();

      if (!userData.containsKey('roles')) continue;

      final List<dynamic> rolesData = userData['roles'] as List<dynamic>;
      final String displayName = _getDisplayName(userData);

      for (final roleData in rolesData) {
        if (roleData is! Map) continue;

        final String roleId = roleData['id'] as String? ?? '';
        if (roleId.isEmpty || !usersByRole.containsKey(roleId)) continue;

        usersByRole[roleId]!.add(
          _createUserInfo(
            userData: userData,
            docId: doc.id,
            displayName: displayName,
            roleName: roleData['name'] as String? ?? '',
          ),
        );
      }
    }
  }

  /// Crea la información del usuario para mostrar
  Map<String, String> _createUserInfo({
    required Map<String, dynamic> userData,
    required String docId,
    required String displayName,
    required String roleName,
  }) => {
    'id': docId,
    'name': displayName,
    'displayName': displayName,
    'email': userData['email']?.toString() ?? '',
    'phone': userData['phone']?.toString() ?? '',
    'roleName': roleName,
  };

  /// Obtiene el nombre completo del usuario o un valor por defecto
  String _getDisplayName(Map<String, dynamic> userData) {
    final List<String> nameParts = [
      userData['name']?.toString() ?? '',
      userData['surname1']?.toString() ?? '',
      userData['surname2']?.toString() ?? '',
    ];

    final String fullName =
        nameParts.where((part) => part.isNotEmpty).join(' ').trim();

    return fullName.isEmpty
        ? userData['email']?.toString() ?? 'Usuario sin nombre'
        : fullName;
  }

  /// Ordena los usuarios por nombre dentro de cada rol
  void _sortUsersByName(Map<String, List<Map<String, dynamic>>> usersByRole) {
    for (final users in usersByRole.values) {
      users.sort((a, b) => a['displayName'].compareTo(b['displayName']));
    }
  }
}
