import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gym_app/models/subscription.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late SubscriptionService subscriptionService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    subscriptionService = SubscriptionService(firestore: fakeFirestore);
  });

  group('hasValidSubscription', () {
    test('should return true when user has valid subscription', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Add a valid subscription
      await fakeFirestore.collection('subscriptions').add({
        'userId': userId,
        'status': 'active',
        'startDate': Timestamp.fromDate(now.subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(now.add(Duration(days: 20))),
        'membershipId': 'mem-1',
      });

      // Act
      final result = await subscriptionService.hasValidSubscription(userId);

      // Assert
      expect(result, true);
    });

    test('should return false when user has expired subscription', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Add an expired subscription
      await fakeFirestore.collection('subscriptions').add({
        'userId': userId,
        'status': 'active',
        'startDate': Timestamp.fromDate(now.subtract(Duration(days: 40))),
        'endDate': Timestamp.fromDate(now.subtract(Duration(days: 10))),
        'membershipId': 'mem-1',
      });

      // Act
      final result = await subscriptionService.hasValidSubscription(userId);

      // Assert
      expect(result, false);
    });

    test('should return false when user has no subscription', () async {
      // Arrange
      final userId = 'test-user-id';

      // Act
      final result = await subscriptionService.hasValidSubscription(userId);

      // Assert
      expect(result, false);
    });
  });

  group('getDaysRemainingInSubscription', () {
    test('should return correct days remaining in subscription', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();
      final endDate = now.add(Duration(days: 15));

      // Add a subscription
      await fakeFirestore.collection('subscriptions').add({
        'userId': userId,
        'status': 'active',
        'startDate': Timestamp.fromDate(now.subtract(Duration(days: 15))),
        'endDate': Timestamp.fromDate(endDate),
        'membershipId': 'mem-1',
      });

      // Act
      final daysRemaining = await subscriptionService
          .getDaysRemainingInSubscription(userId);

      // Assert
      // We expect between 14-16 days remaining (allowing for test execution time)
      expect(daysRemaining, greaterThanOrEqualTo(14));
      expect(daysRemaining, lessThanOrEqualTo(16));
    });

    test('should return 0 when subscription is expired', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Add an expired subscription
      await fakeFirestore.collection('subscriptions').add({
        'userId': userId,
        'status': 'active',
        'startDate': Timestamp.fromDate(now.subtract(Duration(days: 30))),
        'endDate': Timestamp.fromDate(now.subtract(Duration(days: 1))),
        'membershipId': 'mem-1',
      });

      // Act
      final daysRemaining = await subscriptionService
          .getDaysRemainingInSubscription(userId);

      // Assert
      expect(daysRemaining, 0);
    });
  });

  group('create', () {
    test('should add subscription to Firestore', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(Duration(days: 30));

      final subscription = Subscription(
        id: '',
        userId: userId,
        status: 'active',
        startDate: startDate,
        endDate: endDate,
        membershipId: 'mem-1',
      );

      // Act
      await subscriptionService.create(subscription);

      // Assert
      final docs = await fakeFirestore.collection('subscriptions').get();
      expect(docs.docs.length, 1);

      final subscriptionData = docs.docs.first.data();
      expect(subscriptionData['userId'], userId);
      expect(subscriptionData['status'], 'active');
      expect((subscriptionData['startDate'] as Timestamp).toDate(), startDate);
      expect((subscriptionData['endDate'] as Timestamp).toDate(), endDate);
      expect(subscriptionData['membershipId'], 'mem-1');
    });
  });

  group('getActiveSubscriptionForUser', () {
    test('should return active subscription when exists', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: 5));
      final endDate = now.add(Duration(days: 25));

      await fakeFirestore.collection('subscriptions').add({
        'userId': userId,
        'status': 'active',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'membershipId': 'mem-1',
      });

      // Act
      final subscription = await subscriptionService
          .getActiveSubscriptionForUser(userId);

      // Assert
      expect(subscription, isNotNull);
      expect(subscription!.userId, userId);
      expect(subscription.status, 'active');
      expect(subscription.startDate.day, startDate.day);
      expect(subscription.endDate.day, endDate.day);
      expect(subscription.membershipId, 'mem-1');
    });

    test('should return null when no active subscription exists', () async {
      // Arrange
      final userId = 'test-user-id';

      // Act
      final subscription = await subscriptionService
          .getActiveSubscriptionForUser(userId);

      // Assert
      expect(subscription, isNull);
    });
  });
}
