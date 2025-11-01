// lib/routes/AppRoutes.dart

import 'package:flutter/material.dart';
import 'package:gym_app/screens/client/client_home_screen.dart';
import 'package:gym_app/screens/coach/coach_home_screen.dart';
import 'package:gym_app/screens/auth/login_screen.dart';
import 'package:gym_app/screens/owner/owner_home_screen.dart';
import 'package:gym_app/screens/secretary/secretary_home_screen.dart';
import 'package:gym_app/screens/auth/welcome_screen.dart';
import 'package:gym_app/screens/auth/forgot_password_screen.dart';
import 'package:gym_app/screens/auth/reset_password_screen.dart';
import 'package:gym_app/screens/auth/membership_screen.dart';
import 'package:gym_app/screens/owner/plans_screen.dart' show PlansScreen;
import 'package:gym_app/screens/owner/users_screen.dart' show UsersScreen;
import 'package:gym_app/screens/client/qr_scanner_screen.dart';
import 'package:gym_app/screens/shared/user_profile_screen.dart';
import 'package:gym_app/screens/owner/all_attendance_screen.dart';
import 'package:gym_app/screens/auth/CheckInScreen.dart';
import 'package:gym_app/screens/client/client_progress_screen.dart';
import 'package:gym_app/screens/coach/exercises_screen.dart'
    show ExercisesScreen;
import 'package:gym_app/screens/coach/workouts_screen.dart' show WorkoutsScreen;
import 'package:gym_app/screens/coach/assign_workout_screen.dart'
    show AssignWorkoutScreen;

class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String clientHome = '/client-home';
  static const String coachHome = '/coach-home';
  static const String ownerHome = '/owner-home';
  static const String secretaryHome = '/secretary-home';
  static const String memberships = '/memberships';
  static const String plans = '/plans';
  static const String users = '/users';
  static const String qrScanner = '/qr-scanner';
  static const String userProfile = '/user-profile';
  static const String allAttendance = '/all-attendance';  static const String checkIn = '/check-in';
  static const String exercises = '/exercises';
  static const String clientProgress = '/client-progress';
  static const String workouts = '/workouts';
  static const String assignWorkouts = '/assign-workouts';

  static Map<String, WidgetBuilder> routes = {
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    clientHome: (_) => const ClientHomeScreen(),
    coachHome: (_) => const CoachHomeScreen(),
    ownerHome: (_) => const OwnerHomeScreen(),
    secretaryHome: (_) => const SecretaryHomeScreen(),
    memberships: (_) => const MembershipScreen(),
    plans: (_) => const PlansScreen(),
    users: (_) => const UsersScreen(),
    qrScanner: (_) => const QRScannerScreen(),
    userProfile: (_) => const UserProfileScreen(),
    allAttendance: (_) => const AllAttendanceScreen(),    checkIn: (_) => const CheckInScreen(),
    exercises: (_) => const ExercisesScreen(),
    workouts: (_) => const WorkoutsScreen(),
    assignWorkouts: (_) => const AssignWorkoutScreen(),
    clientProgress: (_) => const ClientProgressScreen(),
  };
}
