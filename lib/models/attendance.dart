import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String gymId; // 🔥 NUEVO
  final String tenantId; // 🔥 NUEVO
  final String userId;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime?
  checkOutTime; // Nullable to handle check-ins without check-outs

  Attendance({
    required this.id,
    required this.gymId, // 🔥 NUEVO
    required this.tenantId, // 🔥 NUEVO
    required this.userId,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
  });
  factory Attendance.fromMap(String id, Map<String, dynamic> data) {
    return Attendance(
      id: id,
      gymId: data['gymId'] ?? '', // 🔥 NUEVO
      tenantId: data['tenantId'] ?? '', // 🔥 NUEVO
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      checkOutTime:
          data['checkOutTime'] != null
              ? (data['checkOutTime'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'gymId': gymId, // 🔥 NUEVO
      'tenantId': tenantId, // 🔥 NUEVO
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'checkInTime': Timestamp.fromDate(checkInTime),
    };

    if (checkOutTime != null) {
      map['checkOutTime'] = Timestamp.fromDate(checkOutTime!);
    }

    return map;
  }
}
