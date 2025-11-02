import 'package:cloud_firestore/cloud_firestore.dart';

class TenantSubscription {
  final String id;
  final String tenantId;
  final String planId;
  final String status; // active, cancelled, expired, trial
  final DateTime startDate;
  final DateTime endDate;
  final double paymentAmount;
  final DateTime paymentDate;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  TenantSubscription({
    required this.id,
    required this.tenantId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.paymentAmount,
    required this.paymentDate,
    required this.autoRenew,
    required this.createdAt,
    this.cancelledAt,
  });

  // Crear desde Firestore
  factory TenantSubscription.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TenantSubscription(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      planId: data['planId'] ?? '',
      status: data['status'] ?? 'active',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      paymentAmount: (data['paymentAmount'] ?? 0).toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      autoRenew: data['autoRenew'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      cancelledAt:
          data['cancelledAt'] != null
              ? (data['cancelledAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'planId': planId,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'paymentAmount': paymentAmount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'autoRenew': autoRenew,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  // Verificar si está activa
  bool get isActive {
    return status == 'active' && endDate.isAfter(DateTime.now());
  }

  // Días restantes
  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  // Copiar con modificaciones
  TenantSubscription copyWith({
    String? id,
    String? tenantId,
    String? planId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? paymentAmount,
    DateTime? paymentDate,
    bool? autoRenew,
    DateTime? createdAt,
    DateTime? cancelledAt,
  }) {
    return TenantSubscription(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
