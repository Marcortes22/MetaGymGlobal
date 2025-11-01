import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime?
  checkOutTime; // Nullable to handle check-ins without check-outs

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
  });
  factory Attendance.fromMap(String id, Map<String, dynamic> data) {
    return Attendance(
      id: id,
      userId: data['userId'],
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
