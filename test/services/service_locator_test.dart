import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gym_app/services/service_locator.dart';
import 'package:gym_app/services/attendance_service.dart';
import 'package:gym_app/services/profile_service.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:gym_app/services/user_service.dart';

void main() {
  late ServiceLocator serviceLocator;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    serviceLocator = ServiceLocator();
    serviceLocator.reset();
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
  });

  group('ServiceLocator', () {
    test('should register and resolve services correctly', () {
      // Register services
      serviceLocator.registerService<FirebaseFirestore>(fakeFirestore);
      serviceLocator.registerService<FirebaseAuth>(mockAuth);

      // Register application services
      final subscriptionService = SubscriptionService(firestore: fakeFirestore);
      serviceLocator.registerService<SubscriptionService>(subscriptionService);

      final attendanceService = AttendanceService(
        firestore: fakeFirestore,
        subscriptionService: subscriptionService,
      );
      serviceLocator.registerService<AttendanceService>(attendanceService);

      // Assert services were registered correctly
      expect(
        serviceLocator.getService<FirebaseFirestore>(),
        equals(fakeFirestore),
      );
      expect(serviceLocator.getService<FirebaseAuth>(), equals(mockAuth));
      expect(
        serviceLocator.getService<SubscriptionService>(),
        equals(subscriptionService),
      );
      expect(
        serviceLocator.getService<AttendanceService>(),
        equals(attendanceService),
      );
    });

    test('setupServices should initialize all required services', () {
      // Arrange & Act
      ServiceLocator.setupServices(firestore: fakeFirestore, auth: mockAuth);

      // Assert
      expect(serviceLocator.getService<FirebaseFirestore>(), isNotNull);
      expect(serviceLocator.getService<FirebaseAuth>(), isNotNull);
      expect(serviceLocator.getService<SubscriptionService>(), isNotNull);
      expect(serviceLocator.getService<AttendanceService>(), isNotNull);
      expect(serviceLocator.getService<UserService>(), isNotNull);
      expect(serviceLocator.getService<ProfileService>(), isNotNull);
    });
  });
}
