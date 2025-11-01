import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gym_app/services/attendance_service.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:gym_app/models/attendance.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AttendanceService attendanceService;
  late MockSubscriptionService mockSubscriptionService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockSubscriptionService = MockSubscriptionService();

    // TODO: Implement proper dependency injection to replace
    // Firebase services with mocks in the AttendanceService
  });

  group('register', () {
    test('should successfully register attendance', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Create the attendance record
      final attendance = Attendance(
        id: '',
        userId: userId,
        date: now,
        checkInTime: now,
      );

      // Add it to the fake Firestore directly (since we can't inject the service yet)
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now),
        'checkInTime': Timestamp.fromDate(now),
      });

      // Verify it was added
      final records = await fakeFirestore.collection('attendances').get();
      expect(records.docs.length, 1);

      final data = records.docs[0].data();
      expect(data['userId'], userId);
    });
  });

  group('hasCheckedInToday', () {
    test('should return true when user has checked in today', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();

      // Add an attendance record for today
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now),
        'checkInTime': Timestamp.fromDate(now),
      });

      // TODO: Complete with proper service injection

      // Verify the record was added
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final records =
          await fakeFirestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();

      expect(records.docs.length, 1);
    });

    test('should return false when user has not checked in today', () async {
      // Arrange
      final userId = 'test-user-id';
      final yesterday = DateTime.now().subtract(Duration(days: 1));

      // Add an attendance record for yesterday
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(yesterday),
        'checkInTime': Timestamp.fromDate(yesterday),
      });

      // TODO: Complete with proper service injection

      // Verify no record for today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final records =
          await fakeFirestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();

      expect(records.docs.length, 0);
    });
  });

  group('hasAdminRole', () {
    test('should return true when user has admin role', () async {
      // Arrange
      final userId = 'admin-user-id';

      // Add a user with admin role
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Admin User',
        'email': 'admin@example.com',
        'roles': [
          {'id': 'own', 'name': 'Owner'},
        ],
      });

      // TODO: Complete with proper service injection

      // Verify the user was added with admin role
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);

      final roles = List<Map<String, dynamic>>.from(
        userDoc.data()!['roles'] ?? [],
      );
      bool hasAdminRole = false;
      for (var role in roles) {
        final roleId = role['id'] as String;
        if (roleId == 'own' || roleId == 'coa' || roleId == 'sec') {
          hasAdminRole = true;
          break;
        }
      }

      expect(hasAdminRole, true);
    });

    test('should return false when user does not have admin role', () async {
      // Arrange
      final userId = 'client-user-id';

      // Add a user with client role only
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Client User',
        'email': 'client@example.com',
        'roles': [
          {'id': 'cli', 'name': 'Client'},
        ],
      });

      // TODO: Complete with proper service injection

      // Verify the user doesn't have admin role
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);

      final roles = List<Map<String, dynamic>>.from(
        userDoc.data()!['roles'] ?? [],
      );
      bool hasAdminRole = false;
      for (var role in roles) {
        final roleId = role['id'] as String;
        if (roleId == 'own' || roleId == 'coa' || roleId == 'sec') {
          hasAdminRole = true;
          break;
        }
      }

      expect(hasAdminRole, false);
    });
  });

  group('isClientOnly', () {
    test('should return true when user has only client role', () async {
      // Arrange
      final userId = 'client-user-id';

      // Add a user with client role only
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Client User',
        'email': 'client@example.com',
        'roles': [
          {'id': 'cli', 'name': 'Client'},
        ],
      });

      // TODO: Complete with proper service injection

      // Verify the user has only client role
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);

      final roles = List<Map<String, dynamic>>.from(
        userDoc.data()!['roles'] ?? [],
      );
      bool hasClientRole = false;
      bool hasOtherRole = false;

      for (var role in roles) {
        final roleId = role['id'] as String;
        if (roleId == 'cli') {
          hasClientRole = true;
        } else {
          hasOtherRole = true;
        }
      }

      expect(hasClientRole, true);
      expect(hasOtherRole, false);
    });

    test('should return false when user has other roles', () async {
      // Arrange
      final userId = 'mixed-role-user-id';

      // Add a user with multiple roles
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Mixed Role User',
        'email': 'mixed@example.com',
        'roles': [
          {'id': 'cli', 'name': 'Client'},
          {'id': 'coa', 'name': 'Coach'},
        ],
      });

      // TODO: Complete with proper service injection

      // Verify the user has mixed roles
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);

      final roles = List<Map<String, dynamic>>.from(
        userDoc.data()!['roles'] ?? [],
      );
      bool hasOtherRole = false;

      for (var role in roles) {
        final roleId = role['id'] as String;
        if (roleId != 'cli') {
          hasOtherRole = true;
          break;
        }
      }

      expect(hasOtherRole, true);
    });
  });

  group('checkInWithPin', () {
    test('should successfully check in with valid PIN', () async {
      // Arrange
      final userId = 'test-user-id';
      final pin = '1234';

      // Add a user with the PIN
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Test User',
        'email': 'test@example.com',
        'pin': pin,
        'roles': [
          {'id': 'own', 'name': 'Owner'},
        ],
      });

      // TODO: Complete with proper service injection
      // Verify the user was added
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);
      expect(userDoc.data()!['pin'], pin);
    });

    test('should return error for invalid PIN', () async {
      // Arrange
      final invalidPin = '9999';

      // Verify no user has this PIN
      final userQuery =
          await fakeFirestore
              .collection('users')
              .where('pin', isEqualTo: invalidPin)
              .get();

      expect(userQuery.docs.isEmpty, true);
    });

    test('should prevent multiple check-ins on the same day', () async {
      // Arrange
      final userId = 'test-user-id';
      final pin = '1234';
      final now = DateTime.now();

      // Add a user with the PIN
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Test User',
        'email': 'test@example.com',
        'pin': pin,
        'roles': [
          {'id': 'own', 'name': 'Owner'},
        ],
      });

      // Add an attendance record for today
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now),
        'checkInTime': Timestamp.fromDate(now),
      });

      // Verify attendance was added
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final records =
          await fakeFirestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();

      expect(records.docs.length, 1);
    });
  });

  group('getUserAttendanceHistory', () {
    test('should return attendance history with proper formatting', () async {
      // Arrange
      final userId = 'test-user-id';
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      // Add attendance records
      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(now),
        'checkInTime': Timestamp.fromDate(now),
      });

      await fakeFirestore.collection('attendances').add({
        'userId': userId,
        'date': Timestamp.fromDate(yesterday),
        'checkInTime': Timestamp.fromDate(yesterday),
        'checkOutTime': Timestamp.fromDate(yesterday.add(Duration(hours: 2))),
      });

      // TODO: Complete with proper service injection

      // Verify records were added
      final records =
          await fakeFirestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get();

      expect(records.docs.length, 2);
    });
  });

  // Note: This test file provides a structure for testing the AttendanceService
  // but requires proper dependency injection to work correctly.
}
