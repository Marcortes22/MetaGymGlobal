import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/widgets/KioskModeModal.dart';
import 'package:gym_app/routes/AppRoutes.dart';

class ActivateTotenModeButton extends StatelessWidget {
  final Color? color;

  const ActivateTotenModeButton({super.key, this.color});
  Future<void> activarModoTotenYDeslogear(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Set the totem mode flag to true
    await prefs.setBool('modo_toten', true);
    // Ensure user is logged out when entering totem mode
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Modo Asistencia activado"),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate directly to check-in screen
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.checkIn, (route) => false);
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return KioskModeModal(
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            activarModoTotenYDeslogear(context);
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this button is in a home screen (where we need it to be more compact)
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isInHomeScreen =
        currentRoute == AppRoutes.clientHome ||
        currentRoute == AppRoutes.ownerHome ||
        currentRoute == AppRoutes.coachHome ||
        currentRoute == AppRoutes.secretaryHome;

    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Decide on layout compactness
    final useCompactLayout = isSmallScreen || isLandscape || isInHomeScreen;

    return Container(
      // Use minimal margin when in header/navbar
      margin: EdgeInsets.symmetric(horizontal: isInHomeScreen ? 2 : 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFFA45C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Use smaller radius in header for a more compact look
        borderRadius: BorderRadius.circular(isInHomeScreen ? 15 : 20),
        boxShadow:
            isInHomeScreen
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isInHomeScreen ? 15 : 20),
          onTap: () => _showConfirmationDialog(context),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.transparent,
          child: Padding(
            // Use much smaller padding when in header
            padding: EdgeInsets.symmetric(
              horizontal: useCompactLayout ? 8 : 12,
              vertical: isInHomeScreen ? 3 : (useCompactLayout ? 4 : 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Skip icon on very small screens in header
                if (!(isInHomeScreen && isSmallScreen))
                  Icon(
                    Icons.phonelink_lock,
                    color: color ?? Colors.white,
                    size: useCompactLayout ? 14 : 16,
                  ),
                if (!(isInHomeScreen && isSmallScreen))
                  SizedBox(width: useCompactLayout ? 2 : 4),
                Text(
                  isInHomeScreen
                      ? "Modo Asistencia"
                      : (useCompactLayout
                          ? "Modo Asistencia"
                          : "Activar Modo Asistencia"),
                  style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize:
                        isInHomeScreen ? 10 : (useCompactLayout ? 11 : 13),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
