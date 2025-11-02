class User {
  final String id;
  final String gymId; // 🔥 NUEVO - ID del gimnasio
  final String tenantId; // 🔥 NUEVO - ID del tenant
  final String userId;
  final String name;
  final String surname1;
  final String surname2;
  final String email;
  final String phone;
  final String? pin; // PIN for check-in
  final List<Map<String, String>> roles;
  final int height;
  final int weight;
  final String dateOfBirth;
  final String? membershipId;
  final String? profilePictureUrl;
  User({
    required this.id,
    required this.gymId, // 🔥 NUEVO
    required this.tenantId, // 🔥 NUEVO
    required this.userId,
    required this.name,
    required this.surname1,
    required this.surname2,
    required this.email,
    required this.phone,
    this.pin,
    required this.roles,
    required this.height,
    required this.weight,
    required this.dateOfBirth,
    this.membershipId,
    this.profilePictureUrl,
  });
  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      gymId: data['gymId'] ?? '', // 🔥 NUEVO
      tenantId: data['tenantId'] ?? '', // 🔥 NUEVO
      userId: data['user_id'],
      name: data['name'],
      surname1: data['surname1'],
      surname2: data['surname2'],
      email: data['email'],
      phone: data['phone'],
      pin: data['pin'],
      roles: List<Map<String, String>>.from(
        data['roles'].map((r) => Map<String, String>.from(r)),
      ),
      height: data['height'],
      weight: data['weight'],
      dateOfBirth: data['dateOfBirth'],
      membershipId: data['membershipId'],
      profilePictureUrl: data['profilePictureUrl'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId, // 🔥 NUEVO
      'tenantId': tenantId, // 🔥 NUEVO
      'user_id': userId,
      'name': name,
      'surname1': surname1,
      'surname2': surname2,
      'email': email,
      'phone': phone,
      'pin': pin,
      'roles': roles,
      'height': height,
      'weight': weight,
      'dateOfBirth': dateOfBirth,
      'membershipId': membershipId,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
