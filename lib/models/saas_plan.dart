import 'package:cloud_firestore/cloud_firestore.dart';

class SaasPlan {
  final String id;
  final String name;
  final double price;
  final int maxClients;
  final int maxGyms;
  final String description;
  final List<String> features;
  final bool isActive;
  final String? platformConfigId;
  final DateTime createdAt;

  SaasPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.maxClients,
    required this.maxGyms,
    required this.description,
    required this.features,
    required this.isActive,
    this.platformConfigId,
    required this.createdAt,
  });

  // Crear desde Firestore
  factory SaasPlan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SaasPlan(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      maxClients: data['max_clients'] ?? 0,
      maxGyms: data['max_gyms'] ?? 1,
      description: data['description'] ?? '',
      features: List<String>.from(data['features'] ?? []),
      isActive: data['is_active'] ?? false,
      platformConfigId: data['platform_config_id'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'max_clients': maxClients,
      'max_gyms': maxGyms,
      'description': description,
      'features': features,
      'is_active': isActive,
      'platform_config_id': platformConfigId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copiar con modificaciones
  SaasPlan copyWith({
    String? id,
    String? name,
    double? price,
    int? maxClients,
    int? maxGyms,
    String? description,
    List<String>? features,
    bool? isActive,
    String? platformConfigId,
    DateTime? createdAt,
  }) {
    return SaasPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      maxClients: maxClients ?? this.maxClients,
      maxGyms: maxGyms ?? this.maxGyms,
      description: description ?? this.description,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      platformConfigId: platformConfigId ?? this.platformConfigId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
