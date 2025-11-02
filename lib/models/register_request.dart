import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterRequest {
  final String id;
  final String name;
  final String email;
  final DateTime date;
  final String state; // pending, approved, rejected
  final DateTime createdAt;
  final String companyName;
  final String gymName;
  final String gymAddress;
  final String gymPhone;
  final String adminName;
  final String adminSurname1;
  final String adminSurname2;
  final String adminPhone;
  final String requestedPlan;

  RegisterRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.date,
    required this.state,
    required this.createdAt,
    required this.companyName,
    required this.gymName,
    required this.gymAddress,
    required this.gymPhone,
    required this.adminName,
    required this.adminSurname1,
    required this.adminSurname2,
    required this.adminPhone,
    required this.requestedPlan,
  });

  // Crear desde Firestore
  factory RegisterRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RegisterRequest(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      state: data['state'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      companyName: data['company_name'] ?? '',
      gymName: data['gym_name'] ?? '',
      gymAddress: data['gym_address'] ?? '',
      gymPhone: data['gym_phone'] ?? '',
      adminName: data['admin_name'] ?? '',
      adminSurname1: data['admin_surname1'] ?? '',
      adminSurname2: data['admin_surname2'] ?? '',
      adminPhone: data['admin_phone'] ?? '',
      requestedPlan: data['requested_plan'] ?? '',
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'date': Timestamp.fromDate(date),
      'state': state,
      'createdAt': Timestamp.fromDate(createdAt),
      'company_name': companyName,
      'gym_name': gymName,
      'gym_address': gymAddress,
      'gym_phone': gymPhone,
      'admin_name': adminName,
      'admin_surname1': adminSurname1,
      'admin_surname2': adminSurname2,
      'admin_phone': adminPhone,
      'requested_plan': requestedPlan,
    };
  }

  // Copiar con modificaciones
  RegisterRequest copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? date,
    String? state,
    DateTime? createdAt,
    String? companyName,
    String? gymName,
    String? gymAddress,
    String? gymPhone,
    String? adminName,
    String? adminSurname1,
    String? adminSurname2,
    String? adminPhone,
    String? requestedPlan,
  }) {
    return RegisterRequest(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      date: date ?? this.date,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
      gymName: gymName ?? this.gymName,
      gymAddress: gymAddress ?? this.gymAddress,
      gymPhone: gymPhone ?? this.gymPhone,
      adminName: adminName ?? this.adminName,
      adminSurname1: adminSurname1 ?? this.adminSurname1,
      adminSurname2: adminSurname2 ?? this.adminSurname2,
      adminPhone: adminPhone ?? this.adminPhone,
      requestedPlan: requestedPlan ?? this.requestedPlan,
    );
  }
}
