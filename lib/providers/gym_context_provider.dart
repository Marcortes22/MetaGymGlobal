import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GymContextProvider extends ChangeNotifier {
  String? _currentGymId;
  String? _currentTenantId;
  String? _gymName;
  String? _code;

  String? get currentGymId => _currentGymId;
  String? get currentTenantId => _currentTenantId;
  String? get gymName => _gymName;
  String? get code => _code;

  bool get hasGymContext => _currentGymId != null && _currentTenantId != null;

  // Establecer contexto del gimnasio
  Future<void> setGymContext({
    required String gymId,
    required String tenantId,
    required String gymName,
    String? code,
  }) async {
    _currentGymId = gymId;
    _currentTenantId = tenantId;
    _gymName = gymName;
    _code = code;

    // Guardar en SharedPreferences para persistencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_gym_id', gymId);
    await prefs.setString('current_tenant_id', tenantId);
    await prefs.setString('gym_name', gymName);
    if (code != null) {
      await prefs.setString('gym_code', code);
    }

    notifyListeners();
  }

  // Cargar contexto guardado (al iniciar la app)
  Future<bool> loadGymContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentGymId = prefs.getString('current_gym_id');
      _currentTenantId = prefs.getString('current_tenant_id');
      _gymName = prefs.getString('gym_name');
      _code = prefs.getString('gym_code');

      notifyListeners();
      return hasGymContext;
    } catch (e) {
      print('Error cargando contexto del gym: $e');
      return false;
    }
  }

  // Limpiar contexto (al hacer logout)
  Future<void> clearContext() async {
    _currentGymId = null;
    _currentTenantId = null;
    _gymName = null;
    _code = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_gym_id');
    await prefs.remove('current_tenant_id');
    await prefs.remove('gym_name');
    await prefs.remove('gym_code');

    notifyListeners();
  }

  // Actualizar solo el nombre del gym (si cambia)
  Future<void> updateGymName(String newName) async {
    _gymName = newName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gym_name', newName);

    notifyListeners();
  }
}
