import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String gymId; // 🔥 NUEVO
  final String tenantId; // 🔥 NUEVO
  final String userId;
  final String membershipId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String type;
  final double paymentAmount;
  final DateTime paymentDate;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.gymId, // 🔥 NUEVO
    required this.tenantId, // 🔥 NUEVO
    required this.userId,
    required this.membershipId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.type,
    required this.paymentAmount,
    required this.paymentDate,
    this.cancelledAt,
    required this.createdAt,
  });

  factory Subscription.fromMap(String id, Map<String, dynamic> data) {
    return Subscription(
      id: id,
      gymId: data['gymId'] ?? '', // 🔥 NUEVO
      tenantId: data['tenantId'] ?? '', // 🔥 NUEVO
      userId: data['userId'],
      membershipId: data['membershipId'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'],
      type: data['type'],
      paymentAmount: (data['paymentAmount'] as num).toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      cancelledAt:
          data['cancelledAt'] != null
              ? (data['cancelledAt'] as Timestamp).toDate()
              : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId, // 🔥 NUEVO
      'tenantId': tenantId, // 🔥 NUEVO
      'userId': userId,
      'membershipId': membershipId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'type': type,
      'paymentAmount': paymentAmount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
