import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/attendance_service.dart';
import '../services/subscription_service.dart';
import '../services/service_locator.dart';

/// Service for handling user profile related data
class ProfileService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  late final AttendanceService _attendanceService;
  late final SubscriptionService _subscriptionService;

  // Constructor with optional dependency injection
  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AttendanceService? attendanceService,
    SubscriptionService? subscriptionService,
  }) {
    final serviceLocator = ServiceLocator();

    _firestore =
        firestore ??
        serviceLocator.getService<FirebaseFirestore>() ??
        FirebaseFirestore.instance;

    _auth =
        auth ??
        serviceLocator.getService<FirebaseAuth>() ??
        FirebaseAuth.instance;

    _attendanceService =
        attendanceService ??
        serviceLocator.getService<AttendanceService>() ??
        AttendanceService();

    _subscriptionService =
        subscriptionService ??
        serviceLocator.getService<SubscriptionService>() ??
        SubscriptionService();
  }

  /// Get current logged in user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get full user profile information including membership and roles
  Future<Map<String, dynamic>> getUserProfile({
    String? userId,
    required String gymId,
  }) async {
    try {
      // Use provided userId or current user
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        return {'error': 'No user logged in'};
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return {'error': 'User not found'};
      }

      final userData = userDoc.data()!;

      // Get membership info if available
      String? membershipName;
      String? membershipEndDate;
      int daysRemaining = 0;

      if (userData['membershipId'] != null) {
        final membershipDoc =
            await _firestore
                .collection('memberships')
                .doc(userData['membershipId'])
                .get();

        if (membershipDoc.exists && membershipDoc.data() != null) {
          membershipName = membershipDoc.data()!['name'];
        } // Get subscription details
        daysRemaining = await _subscriptionService
            .getDaysRemainingInSubscription(uid, gymId);

        final subscription = await _subscriptionService
            .getActiveSubscriptionForUser(uid, gymId);
        if (subscription != null) {
          final end = subscription.endDate;
          membershipEndDate = '${end.day}/${end.month}/${end.year}';
        }
      }

      // Calculate age
      int age = 0;
      if (userData['dateOfBirth'] != null &&
          userData['dateOfBirth'].toString().isNotEmpty) {
        final dob = DateTime.tryParse(userData['dateOfBirth']);
        if (dob != null) {
          final today = DateTime.now();
          age = today.year - dob.year;
          if (today.month < dob.month ||
              (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
        }
      }

      // Format the roles for display
      final rolesList = List<Map<String, dynamic>>.from(
        userData['roles'] ?? [],
      );
      final List<String> displayRoles =
          rolesList.map((role) => role['name'].toString()).toList();

      // Get attendance statistics
      final attendanceStats = await getAttendanceStats(uid, gymId);

      return {
        'userId': uid,
        'userInfo': {
          'name': userData['name'] ?? '',
          'surname1': userData['surname1'] ?? '',
          'surname2': userData['surname2'] ?? '',
          'fullName':
              '${userData['name'] ?? ''} ${userData['surname1'] ?? ''} ${userData['surname2'] ?? ''}',
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'height': userData['height'] ?? 0,
          'weight': userData['weight'] ?? 0,
          'age': age,
          'dateOfBirth': userData['dateOfBirth'] ?? '',
          'profilePictureUrl': userData['profilePictureUrl'],
          'pin': userData['pin'] ?? '----', // Adding PIN code to user info
        },
        'membershipInfo': {
          'membershipId': userData['membershipId'],
          'membershipName': membershipName,
          'hasValidSubscription': daysRemaining > 0,
          'daysRemaining': daysRemaining,
          'endDate': membershipEndDate,
        },
        'roles': displayRoles,
        'attendanceStats': attendanceStats,
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return {'error': 'Failed to load user profile: $e'};
    }
  }

  /// Get user's attendance statistics
  Future<Map<String, dynamic>> getAttendanceStats(
    String userId,
    String gymId,
  ) async {
    try {
      // Get today's date information
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Query all attendance records for this user in this gym
      final attendanceQuery =
          await _firestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .where('gymId', isEqualTo: gymId)
              .orderBy('date', descending: true)
              .get();

      final allRecords = attendanceQuery.docs;

      // Calculate monthly check-ins
      int monthlyCheckIns = 0;
      for (var doc in allRecords) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        if (date.isAfter(startOfMonth) ||
            (date.year == startOfMonth.year &&
                date.month == startOfMonth.month &&
                date.day == startOfMonth.day)) {
          monthlyCheckIns++;
        }
      }

      // Calculate current streak
      int currentStreak = 0;
      DateTime? lastCheckIn;

      if (allRecords.isNotEmpty) {
        // Get the last check-in date
        lastCheckIn = (allRecords.first.data()['date'] as Timestamp).toDate();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        // Check if the last check-in was today or yesterday
        final lastDay = DateTime(
          lastCheckIn.year,
          lastCheckIn.month,
          lastCheckIn.day,
        );

        if (lastDay.isAtSameMomentAs(today) ||
            lastDay.isAtSameMomentAs(yesterday)) {
          // Start counting the streak
          currentStreak = 1;

          // Create set of dates with check-ins for efficient lookup
          final Set<String> checkInDates = {};
          for (var doc in allRecords) {
            final date = (doc.data()['date'] as Timestamp).toDate();
            checkInDates.add('${date.year}-${date.month}-${date.day}');
          }

          // Check previous days for streak
          for (int i = lastDay.isAtSameMomentAs(today) ? 1 : 2; i < 60; i++) {
            final checkDate = today.subtract(Duration(days: i));
            final dateKey =
                '${checkDate.year}-${checkDate.month}-${checkDate.day}';

            if (checkInDates.contains(dateKey)) {
              currentStreak++;
            } else {
              // Streak broken
              break;
            }
          }
        }
      }

      return {
        'totalCheckIns': allRecords.length,
        'monthlyCheckIns': monthlyCheckIns,
        'currentStreak': currentStreak,
        'lastCheckIn': lastCheckIn,
        'hasCheckedInToday': await _attendanceService.hasCheckedInToday(
          userId,
          gymId,
        ),
      };
    } catch (e) {
      print('Error getting attendance stats: $e');
      return {
        'totalCheckIns': 0,
        'monthlyCheckIns': 0,
        'currentStreak': 0,
        'hasCheckedInToday': false,
      };
    }
  }

  /// Get user's recent attendance history
  Future<List<Map<String, dynamic>>> getUserAttendanceHistory(
    String userId,
    String gymId, {
    int limit = 20,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .where('gymId', isEqualTo: gymId)
              .orderBy('date', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final checkInTime = (data['checkInTime'] as Timestamp).toDate();
        DateTime? checkOutTime;

        if (data['checkOutTime'] != null) {
          checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
        }

        // Calculate duration if check-out exists
        String duration = "N/A";
        if (checkOutTime != null) {
          final durationMinutes =
              checkOutTime.difference(checkInTime).inMinutes;
          duration = "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";
        }

        return {
          'id': doc.id,
          'date': date,
          'formattedDate': "${date.day}/${date.month}/${date.year}",
          'checkInTime': checkInTime,
          'formattedCheckInTime':
              "${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}",
          'checkOutTime': checkOutTime,
          'formattedCheckOutTime':
              checkOutTime != null
                  ? "${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}"
                  : "N/A",
          'duration': duration,
          'weekday': _getWeekdayName(date.weekday),
        };
      }).toList();
    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  /// Get attendance records for all users (for admin views)
  Future<List<Map<String, dynamic>>> getAllUsersAttendance({
    required String gymId,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('attendances')
          .where('gymId', isEqualTo: gymId);

      // Apply date filters if provided
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final snapshot =
          await query.orderBy('date', descending: true).limit(limit).get();
      // Get all user IDs
      final userIds =
          snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data != null ? data['userId'] as String? ?? '' : '';
              })
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

      // Fetch user data in batch
      final userDocs = await Future.wait(
        userIds.map((id) => _firestore.collection('users').doc(id).get()),
      );

      // Create user data map for quick lookup
      final Map<String, Map<String, dynamic>> userMap = {};
      for (final doc in userDocs) {
        if (doc.exists && doc.data() != null) {
          userMap[doc.id] = doc.data()!;
        }
      } // Transform attendance data with user information
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          // Skip invalid data
          return <String, dynamic>{
            'id': doc.id,
            'userId': 'unknown',
            'userName': 'Datos no disponibles',
            'date': DateTime.now(),
            'formattedDate': 'N/A',
            'checkInTime': DateTime.now(),
            'formattedCheckInTime': 'N/A',
            'checkOutTime': null,
            'formattedCheckOutTime': 'N/A',
            'duration': 'N/A',
            'weekday': 'N/A',
          };
        }

        final userId = data['userId'] as String;
        final userData = userMap[userId];

        final date = (data['date'] as Timestamp).toDate();
        final checkInTime = (data['checkInTime'] as Timestamp).toDate();
        DateTime? checkOutTime;

        if (data['checkOutTime'] != null) {
          checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
        }

        String duration = "N/A";
        if (checkOutTime != null) {
          final durationMinutes =
              checkOutTime.difference(checkInTime).inMinutes;
          duration = "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";
        }

        // Create user name safely handling null userData
        String userName = "Usuario desconocido";
        if (userData != null) {
          final name = userData['name'] as String? ?? '';
          final surname = userData['surname1'] as String? ?? '';
          userName = "$name $surname".trim();
          if (userName.isEmpty) {
            userName = "Usuario desconocido";
          }
        }

        return {
          'id': doc.id,
          'userId': userId,
          'userName': userName,
          'date': date,
          'formattedDate': "${date.day}/${date.month}/${date.year}",
          'checkInTime': checkInTime,
          'formattedCheckInTime':
              "${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}",
          'checkOutTime': checkOutTime,
          'formattedCheckOutTime':
              checkOutTime != null
                  ? "${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}"
                  : "N/A",
          'duration': duration,
          'weekday': _getWeekdayName(date.weekday),
        };
      }).toList();
    } catch (e) {
      print('Error getting all attendance: $e');
      return [];
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method to get weekday name in Spanish
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }
}
