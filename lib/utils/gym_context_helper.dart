import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gym_context_provider.dart';

/// Helper class to easily access gym context from any widget
///
/// Usage in any screen:
/// ```dart
/// final gymContext = GymContext.of(context);
///
/// // Use in service calls:
/// await userService.getAllUsers(gymContext.gymId);
/// await membershipService.getAllMemberships(gymContext.gymId);
/// ```
class GymContext {
  final String gymId;
  final String tenantId;
  final String gymName;
  final String? code;

  GymContext({
    required this.gymId,
    required this.tenantId,
    required this.gymName,
    this.code,
  });

  /// Get gym context from BuildContext
  /// Throws an error if gym context is not available
  static GymContext of(BuildContext context) {
    final provider = Provider.of<GymContextProvider>(context, listen: false);

    if (!provider.hasGymContext) {
      throw Exception(
        'Gym context not available. User must login with gym code first.',
      );
    }

    return GymContext(
      gymId: provider.currentGymId!,
      tenantId: provider.currentTenantId!,
      gymName: provider.gymName!,
      code: provider.code,
    );
  }

  /// Try to get gym context, returns null if not available
  /// Use this when you want to handle missing context gracefully
  static GymContext? tryOf(BuildContext context) {
    try {
      return of(context);
    } catch (_) {
      return null;
    }
  }

  /// Check if gym context is available
  static bool isAvailable(BuildContext context) {
    final provider = Provider.of<GymContextProvider>(context, listen: false);
    return provider.hasGymContext;
  }

  /// Watch for changes in gym context
  /// Use this when you need to rebuild when context changes
  static GymContext watch(BuildContext context) {
    final provider = Provider.of<GymContextProvider>(context, listen: true);

    if (!provider.hasGymContext) {
      throw Exception(
        'Gym context not available. User must login with gym code first.',
      );
    }

    return GymContext(
      gymId: provider.currentGymId!,
      tenantId: provider.currentTenantId!,
      gymName: provider.gymName!,
      code: provider.code,
    );
  }

  @override
  String toString() {
    return 'GymContext(gymId: $gymId, tenantId: $tenantId, gymName: $gymName, code: $code)';
  }
}

/// Extension methods for easier access to gym context
extension GymContextExtension on BuildContext {
  /// Quick access to gym context
  /// Example: context.gymContext.gymId
  GymContext get gymContext => GymContext.of(this);

  /// Try to get gym context without throwing
  GymContext? get gymContextOrNull => GymContext.tryOf(this);

  /// Check if gym context is available
  bool get hasGymContext => GymContext.isAvailable(this);

  /// Watch gym context for changes
  GymContext get watchGymContext => GymContext.watch(this);
}
