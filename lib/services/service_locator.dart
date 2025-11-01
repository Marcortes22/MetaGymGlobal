import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/services/attendance_service.dart';
import 'package:gym_app/services/profile_service.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:gym_app/services/user_service.dart';

/// A simple service locator pattern implementation for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  // Factory constructor
  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  // Mapping of service types to their implementations
  final _services = <Type, dynamic>{};

  /// Register a service implementation with the locator
  void registerService<T>(T service) {
    _services[T] = service;
  }

  /// Get a service implementation by type
  T? getService<T>() {
    return _services[T] as T?;
  }

  /// Register services with either real implementations or test mocks
  static void setupServices({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    final locator = ServiceLocator();

    // Use provided instances or create real ones
    final firestoreInstance = firestore ?? FirebaseFirestore.instance;
    final authInstance = auth ?? FirebaseAuth.instance;

    // Register Firebase services
    locator.registerService<FirebaseFirestore>(firestoreInstance);
    locator.registerService<FirebaseAuth>(authInstance);

    // Register application services with dependencies
    final subscriptionService = SubscriptionService();
    locator.registerService<SubscriptionService>(subscriptionService);

    final attendanceService = AttendanceService();
    locator.registerService<AttendanceService>(attendanceService);

    final userService = UserService();
    locator.registerService<UserService>(userService);

    final profileService = ProfileService();
    locator.registerService<ProfileService>(profileService);
  }

  /// Reset all services (useful for testing)
  void reset() {
    _services.clear();
  }
}
