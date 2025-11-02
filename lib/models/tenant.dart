import 'package:cloud_firestore/cloud_firestore.dart';

class Tenant {
  final String id;
  final String code;
  final bool isActive;
  final DateTime createdAt;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String ownerId;
  final String currentPlanId;
  final DateTime subscriptionEndDate;

  Tenant({
    required this.id,
    required this.code,
    required this.isActive,
    required this.createdAt,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.ownerId,
    required this.currentPlanId,
    required this.subscriptionEndDate,
  });

  // Crear desde Firestore
  factory Tenant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tenant(
      id: doc.id,
      code: data['code'] ?? '',
      isActive: data['is_active'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      companyName: data['companyName'] ?? '',
      companyEmail: data['companyEmail'] ?? '',
      companyPhone: data['companyPhone'] ?? '',
      ownerId: data['ownerId'] ?? '',
      currentPlanId: data['currentPlanId'] ?? '',
      subscriptionEndDate: (data['subscriptionEndDate'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'is_active': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'companyName': companyName,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'ownerId': ownerId,
      'currentPlanId': currentPlanId,
      'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
    };
  }

  // Copiar con modificaciones
  Tenant copyWith({
    String? id,
    String? code,
    bool? isActive,
    DateTime? createdAt,
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? ownerId,
    String? currentPlanId,
    DateTime? subscriptionEndDate,
  }) {
    return Tenant(
      id: id ?? this.id,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      ownerId: ownerId ?? this.ownerId,
      currentPlanId: currentPlanId ?? this.currentPlanId,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }
}
