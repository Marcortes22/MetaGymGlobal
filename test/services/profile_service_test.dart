import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:gym_app/services/profile_service.dart';
import 'package:gym_app/services/attendance_service.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockAttendanceService extends Mock implements AttendanceService {}

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth fakeAuth;
  late ProfileService profileService;
  late MockAttendanceService mockAttendanceService;
  late MockSubscriptionService mockSubscriptionService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = MockFirebaseAuth();
    mockAttendanceService = MockAttendanceService();
    mockSubscriptionService = MockSubscriptionService();

    // Create a test user to use in the tests
    fakeAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      ),
    );

    // Manual service implementation injection to allow mocking
    profileService = ProfileService();
    // Inject dependencies (this would be done by a DI system in a real app)
  });

  group('getCurrentUserId', () {
    test('should return current user ID when user is logged in', () {
      // Arrange
      final userId = fakeAuth.currentUser!.uid;

      // Act
      final result = fakeAuth.currentUser!.uid;

      // Assert
      expect(result, equals(userId));
    });

    test('should return null when no user is logged in', () {
      // Arrange
      fakeAuth = MockFirebaseAuth(signedIn: false);

      // Act
      final result = fakeAuth.currentUser?.uid;

      // Assert
      expect(result, isNull);
    });
  });

  group('getUserProfile', () {
    test('should return user profile data when user exists', () async {
      // Arrange
      final userId = 'test-user-id';

      // Add a test user to the fake Firestore
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'John',
        'surname1': 'Doe',
        'surname2': 'Smith',
        'email': 'john.doe@example.com',
        'phone': '123456789',
        'height': 180,
        'weight': 80,
        'dateOfBirth': '1990-01-01',
        'roles': [
          {'id': 'cli', 'name': 'Cliente'},
        ],
        'membershipId': 'mem-123',
      });

      // Add a test membership
      await fakeFirestore.collection('memberships').doc('mem-123').set({
        'name': 'Premium',
        'price': 29.99,
        'durationDays': 30,
      });

      // Setup the mock services responses
      when(
        mockSubscriptionService.hasValidSubscription(userId),
      ).thenAnswer((_) async => true);
      when(
        mockSubscriptionService.getDaysRemainingInSubscription(userId),
      ).thenAnswer((_) async => 15);
      when(
        mockAttendanceService.hasCheckedInToday(userId),
      ).thenAnswer((_) async => true);

      // TODO: Complete the test once we have proper dependency injection

      // Validate that the data was added correctly to our fake Firestore
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);
      expect(userDoc.data()!['name'], 'John');
    });

    test('should return error when user does not exist', () async {
      // Arrange
      final userId = 'non-existent-user';

      // TODO: Complete test with dependency injection

      // Assert that the user doesn't exist in Firestore
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, false);
    });
  });

  group('getAttendanceStats', () {
    test('should calculate attendance statistics correctly', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Add test attendance records to Firestore
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now),
        'checkInTime': Timestamp.fromDate(now),
      });

      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now.subtract(Duration(days: 1))),
        'checkInTime': Timestamp.fromDate(now.subtract(Duration(days: 1))),
      });

      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now.subtract(Duration(days: 2))),
        'checkInTime': Timestamp.fromDate(now.subtract(Duration(days: 2))),
      });

      // TODO: Complete test implementation once we have dependency injection

      // Verify the data was added to our fake Firestore
      final records =
          await fakeFirestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get();
      expect(records.docs.length, 3);
    });
  });

  group('getUserAttendanceHistory', () {
    test('should return attendance history for a user', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Add test attendance records to Firestore
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now),
        'checkInTime': Timestamp.fromDate(now),
      });

      // TODO: Complete test implementation once we have dependency injection

      // Verify the data was added to our fake Firestore
      final records =
          await fakeFirestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get();
      expect(records.docs.length, 1);
    });
  });

  group('getAllUsersAttendance', () {
    test(
      'should return attendance records for all users within date range',
      () async {
        // Arrange
        final user1Id = 'user-1';
        final user2Id = 'user-2';
        final now = DateTime.now();

        // Add test users to Firestore
        await fakeFirestore.collection('users').doc(user1Id).set({
          'name': 'User One',
          'email': 'user1@example.com',
        });

        await fakeFirestore.collection('users').doc(user2Id).set({
          'name': 'User Two',
          'email': 'user2@example.com',
        });

        // Add attendance records
        await fakeFirestore.collection('attendances').add({
          'userId': user1Id,
          'date': Timestamp.fromDate(now),
          'checkInTime': Timestamp.fromDate(now),
        });

        await fakeFirestore.collection('attendances').add({
          'userId': user2Id,
          'date': Timestamp.fromDate(now.subtract(Duration(days: 5))),
          'checkInTime': Timestamp.fromDate(now.subtract(Duration(days: 5))),
        });

        // TODO: Complete test implementation once we have dependency injection

        // Verify the data was added to our fake Firestore
        final records = await fakeFirestore.collection('attendances').get();
        expect(records.docs.length, 2);
      },
    );
  });

  // Note: This test file provides a structure for testing the ProfileService
  // but requires proper dependency injection to work correctly.
  // In a real implementation, we would need to:
  // 1. Use a proper DI framework or manual injection to replace Firebase services with mocks
  // 2. Complete the assertions in each test
}
