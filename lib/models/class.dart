import 'package:cloud_firestore/cloud_firestore.dart';

class GymClass {
  final String id;
  final String name;
  final String instructorId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final List<String> attendees;

  GymClass({
    required this.id,
    required this.name,
    required this.instructorId,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    required this.attendees,
  });

  factory GymClass.fromMap(String id, Map<String, dynamic> data) {
    return GymClass(
      id: id,
      name: data['name'],
      instructorId: data['instructorId'],
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      capacity: data['capacity'],
      attendees: List<String>.from(data['attendees']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'instructorId': instructorId,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'capacity': capacity,
      'attendees': attendees,
    };
  }
}
