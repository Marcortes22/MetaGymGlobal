import 'package:cloud_firestore/cloud_firestore.dart';

class Gym {
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final bool isActive;
  final DateTime createdAt;

  Gym({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.isActive,
    required this.createdAt,
  });

  // Crear desde Firestore
  factory Gym.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Gym(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      isActive: data['is_active'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'is_active': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copiar con modificaciones
  Gym copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? code,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Gym(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      code: code ?? this.code,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
