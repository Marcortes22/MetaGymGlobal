import 'package:cloud_firestore/cloud_firestore.dart';

class Membership {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final String description;
  final DateTime createdAt;

  Membership({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.description,
    required this.createdAt,
  });

  factory Membership.fromMap(String id, Map<String, dynamic> data) {
    return Membership(
      id: id,
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      durationDays: data['durationDays'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
