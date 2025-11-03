import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';
import '../services/service_locator.dart';

class SubscriptionService {
  late final CollectionReference _collection;

  // Constructor with optional dependency injection
  SubscriptionService({FirebaseFirestore? firestore}) {
    final serviceLocator = ServiceLocator();

    final firestoreInstance =
        firestore ??
        serviceLocator.getService<FirebaseFirestore>() ??
        FirebaseFirestore.instance;

    _collection = firestoreInstance.collection('subscriptions');
  }

  Future<void> create(Subscription sub) async {
    await _collection.add(sub.toMap());
  }

  // 🔥 ACTUALIZADO - Obtener todas las suscripciones por gym
  Future<List<Subscription>> getAll(String gymId) async {
    final snapshot = await _collection.where('gymId', isEqualTo: gymId).get();
    return snapshot.docs
        .map(
          (doc) =>
              Subscription.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 ACTUALIZADO - Get active subscription for a user (en este gym)
  Future<Subscription?> getActiveSubscriptionForUser(
    String userId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId) // 🔥 NUEVO
            .where('status', isEqualTo: 'active')
            .orderBy('endDate', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return Subscription.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // 🔥 ACTUALIZADO - Check if a user has a valid subscription (not expired)
  Future<bool> hasValidSubscription(String userId, String gymId) async {
    final subscription = await getActiveSubscriptionForUser(userId, gymId);
    if (subscription == null) {
      return false;
    }

    // Check if subscription is still valid (not expired)
    final now = DateTime.now();
    return subscription.endDate.isAfter(now);
  }

  // 🔥 ACTUALIZADO - Calculate days remaining in subscription
  Future<int> getDaysRemainingInSubscription(
    String userId,
    String gymId,
  ) async {
    final subscription = await getActiveSubscriptionForUser(userId, gymId);
    if (subscription == null) {
      return 0;
    }

    final now = DateTime.now();
    if (subscription.endDate.isBefore(now)) {
      return 0;
    }

    // Calcular la diferencia incluyendo el día actual
    final difference = subscription.endDate.difference(now);
    return (difference.inHours / 24)
        .ceil(); // Redondear hacia arriba para incluir el día actual
  }

  // 🔥 NUEVO - Obtener historial de suscripciones de un usuario
  Future<List<Subscription>> getUserSubscriptionHistory(
    String userId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map(
          (doc) =>
              Subscription.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 NUEVO - Cancelar suscripción
  Future<void> cancelSubscription(String subscriptionId) async {
    await _collection.doc(subscriptionId).update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
