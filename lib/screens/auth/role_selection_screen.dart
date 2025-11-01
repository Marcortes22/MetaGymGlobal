import 'package:flutter/material.dart';
import 'package:gym_app/routes/AppRoutes.dart';

class RoleSelectionScreen extends StatelessWidget {
  final List<String>? roles;

  const RoleSelectionScreen({super.key, this.roles});

  @override
  Widget build(BuildContext context) {
    // Obtener roles del constructor o de los argumentos de navegación
    final effectiveRoles =
        roles ??
        (ModalRoute.of(context)?.settings.arguments as List<String>?) ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed:
              () => Navigator.pushReplacementNamed(context, AppRoutes.welcome),
        ),
        title: const Text(
          'Selecciona tu rol',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body:
          effectiveRoles.isEmpty
              ? const Center(
                child: Text(
                  'No tienes roles asignados',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(24),
                children:
                    effectiveRoles.map((role) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            switch (role) {
                              case 'cli':
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.clientHome,
                                );
                                break;
                              case 'coa':
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.coachHome,
                                );
                                break;
                              case 'own':
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.ownerHome,
                                );
                                break;
                              case 'sec':
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.secretaryHome,
                                );
                                break;
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIconForRole(role),
                                color: const Color(0xFFFF8C42),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ingresar como ${getRoleName(role)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  String getRoleName(String role) {
    switch (role) {
      case 'cli':
        return 'Cliente';
      case 'coa':
        return 'Entrenador';
      case 'own':
        return 'Administrador';
      case 'sec':
        return 'Secretaria';
      default:
        return 'Desconocido';
    }
  }

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'cli':
        return Icons.person_outline;
      case 'coa':
        return Icons.fitness_center;
      case 'own':
        return Icons.admin_panel_settings_outlined;
      case 'sec':
        return Icons.support_agent;
      default:
        return Icons.person_outline;
    }
  }
}
