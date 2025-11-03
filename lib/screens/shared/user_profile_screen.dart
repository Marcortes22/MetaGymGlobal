import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_app/services/profile_service.dart';
import 'package:gym_app/services/attendance_service.dart';
import '../../utils/gym_context_helper.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isAdminView;

  const UserProfileScreen({Key? key, this.userId, this.isAdminView = false})
    : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final AttendanceService _attendanceService = AttendanceService();
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _hasOngoingSession = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gymContext = context.gymContext;
      final userId = widget.userId ?? _profileService.getCurrentUserId();
      if (userId != null) {
        final profileData = await _profileService.getUserProfile(
          userId: userId,
          gymId: gymContext.gymId,
        );
        final attendanceHistory = await _profileService
            .getUserAttendanceHistory(userId, gymContext.gymId);

        // Check if user has an ongoing session
        final sessionStatus = await _attendanceService.hasOngoingSession(
          userId,
          gymContext.gymId, // 🔥 AGREGADO
        );
        final hasOngoing = sessionStatus['hasOngoing'] == true;

        setState(() {
          _profileData = profileData;
          _attendanceHistory = attendanceHistory;
          _hasOngoingSession = hasOngoing;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _profileData = {'error': 'No user logged in'};
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _profileData = {'error': 'Error loading profile: $e'};
      });
    }
  }

  // Check if the user has admin privileges (owner, secretary, coach)
  bool _hasAdminAccess() {
    final roles = _profileData['roles'] as List<String>;
    return roles.any(
      (role) =>
          role.toLowerCase().contains('admin') ||
          role.toLowerCase().contains('owner') ||
          role.toLowerCase().contains('secret') ||
          role.toLowerCase().contains('coach'),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!widget.isAdminView)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFF8C42)),
              onPressed: () => _showLogoutConfirmation(context),
              tooltip: 'Cerrar sesión',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF8C42),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Membresía'),
            Tab(text: 'Asistencia'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
                ),
              )
              : _profileData.containsKey('error')
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profileData['error'],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                      ),
                      onPressed: _loadUserProfile,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileInfo(),
                  _buildMembershipInfo(),
                  _checkAdminAccessForAttendance(),
                ],
              ),
    );
  }

  // Display attendance records or access denied based on user role
  Widget _checkAdminAccessForAttendance() {
    // If it's admin view or the user has admin access, show the attendance
    if (widget.isAdminView || _hasAdminAccess()) {
      return _buildAttendanceInfo();
    } else {
      // Otherwise show access denied message
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              "Acceso Restringido",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Solo los administradores, secretarias y entrenadores pueden ver el historial de asistencia.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfileInfo() {
    final userInfo = _profileData['userInfo'] as Map<String, dynamic>;
    final roles = _profileData['roles'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF333333),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image:
                        userInfo['profilePictureUrl'] != null
                            ? DecorationImage(
                              image: NetworkImage(
                                userInfo['profilePictureUrl'],
                              ),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      userInfo['profilePictureUrl'] == null
                          ? const Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white54,
                            ),
                          )
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  userInfo['fullName'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  children:
                      roles.map((role) {
                        return Chip(
                          backgroundColor: const Color(
                            0xFFFF8C42,
                          ).withOpacity(0.2),
                          label: Text(
                            role,
                            style: const TextStyle(
                              color: Color(0xFFFF8C42),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Información Personal',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow('Email', userInfo['email']),
            _buildInfoRow('Teléfono', userInfo['phone']),
            _buildInfoRow('Fecha de Nacimiento', userInfo['dateOfBirth']),
            _buildInfoRow('Edad', '${userInfo['age']} años'),
            _buildInfoRow('PIN de Acceso', userInfo['pin'] ?? '----'),
          ]),
          const SizedBox(height: 24),
          const Text(
            'Información Física',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow('Altura', '${userInfo['height']} cm'),
            _buildInfoRow('Peso', '${userInfo['weight']} kg'),
            if (userInfo['height'] > 0 && userInfo['weight'] > 0)
              _buildInfoRow(
                'IMC',
                _calculateBMI(userInfo['height'], userInfo['weight']),
              ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _calculateBMI(int heightCm, int weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 'N/A';

    // Convert height from cm to m
    final heightM = heightCm / 100;
    // Calculate BMI: weight (kg) / height² (m²)
    final bmi = weightKg / (heightM * heightM);

    String category;
    if (bmi < 18.5) {
      category = 'Bajo peso';
    } else if (bmi < 25) {
      category = 'Normal';
    } else if (bmi < 30) {
      category = 'Sobrepeso';
    } else {
      category = 'Obesidad';
    }

    return '${bmi.toStringAsFixed(1)} ($category)';
  }

  Widget _buildMembershipInfo() {
    final membershipInfo =
        _profileData['membershipInfo'] as Map<String, dynamic>;
    final attendanceStats =
        _profileData['attendanceStats'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C42), Color(0xFFFFA45C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Membresía',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        membershipInfo['hasValidSubscription']
                            ? 'ACTIVA'
                            : 'INACTIVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  membershipInfo['membershipName'] ?? 'Sin membresía',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (membershipInfo['daysRemaining'] > 0) ...[
                  const Text(
                    'Días restantes',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value:
                        membershipInfo['daysRemaining'] < 30
                            ? membershipInfo['daysRemaining'] / 30
                            : 1.0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${membershipInfo['daysRemaining']} días restantes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (membershipInfo['endDate'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Fecha de vencimiento: ${membershipInfo['endDate']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (membershipInfo['hasValidSubscription'] &&
                    !widget.isAdminView) ...[
                  const SizedBox(height: 24),
                  // Botón de check-in eliminado (QR no funciona)
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Estadísticas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total\nAsistencias',
                  attendanceStats['totalCheckIns'].toString(),
                  Icons.calendar_month,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Este\nMes',
                  attendanceStats['monthlyCheckIns'].toString(),
                  Icons.date_range,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Racha\nActual',
                  attendanceStats['currentStreak'].toString(),
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (attendanceStats['lastCheckIn'] != null) ...[
            Text(
              'Último check-in: ${DateFormat('dd/MM/yyyy HH:mm').format(attendanceStats['lastCheckIn'])}',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
          if (!attendanceStats['hasCheckedInToday']) ...[
            _buildWarningCard(
              'No has registrado tu asistencia hoy',
              'Recuerda registrar tu asistencia para mantener tu racha.',
              Icons.assignment_late,
            ),
          ] else if (_hasOngoingSession) ...[
            // Show check-out card if there's an ongoing session
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.redAccent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Sesión en progreso',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Has registrado tu entrada hoy. No olvides registrar tu salida al terminar tu entrenamiento.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // ElevatedButton.icon(
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.redAccent,
                  //     padding: const EdgeInsets.symmetric(vertical: 12),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //   ),
                  //   icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  //   label: const Text(
                  //     'Registrar salida ahora',
                  //     style: TextStyle(
                  //       color: Colors.white,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  //   onPressed: _processDirectCheckOut,
                  // ),
                ],
              ),
            ),
          ] else ...[
            _buildSuccessCard(
              'Ya has registrado tu asistencia hoy',
              '¡Buen trabajo! Has asistido al gimnasio hoy.',
              Icons.check_circle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial de Asistencia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFFFF8C42)),
                onPressed: () async {
                  final gymContext = context.gymContext;
                  final userId =
                      widget.userId ?? _profileService.getCurrentUserId();
                  if (userId != null) {
                    final history = await _profileService
                        .getUserAttendanceHistory(userId, gymContext.gymId);
                    setState(() {
                      _attendanceHistory = history;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        _attendanceHistory.isEmpty
            ? const Expanded(
              child: Center(
                child: Text(
                  'No hay registros de asistencia',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
            : Expanded(
              child: ListView.builder(
                itemCount: _attendanceHistory.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final attendance = _attendanceHistory[index];
                  return _buildAttendanceCard(attendance);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> attendance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C42).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Color(0xFFFF8C42),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      attendance['formattedDate'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  attendance['weekday'],
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrada',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendance['formattedCheckInTime'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Salida',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendance['formattedCheckOutTime'],
                        style: TextStyle(
                          color:
                              attendance['formattedCheckOutTime'] == 'N/A'
                                  ? Colors.white38
                                  : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duración',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendance['duration'],
                        style: TextStyle(
                          color:
                              attendance['duration'] == 'N/A'
                                  ? Colors.white38
                                  : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF8C42), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildWarningCard(String title, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade800.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade800.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.amber.shade100, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(String title, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade800.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.green.shade100, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Color(0xFFFF8C42)),
                SizedBox(width: 10),
                Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              '¿Estás seguro de que deseas cerrar sesión?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _profileService.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  }
                },
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
    );
  }

  // Process direct check-out for the user
  // Future<void> _processDirectCheckOut() async {
  //   try {
  //     final userId = widget.userId ?? _profileService.getCurrentUserId();
  //     if (userId == null) {
  //       _showMessage('No hay un usuario autenticado', isError: true);
  //       return;
  //     }

  //     // Show loading indicator
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     // Process the check-out
  //     final response = await _attendanceService.checkOut(userId);

  //     setState(() {
  //       _isLoading = false;
  //     });

  //     if (response['success']) {
  //       _showMessage(
  //         'Salida registrada exitosamente. Tiempo en el gimnasio: ${response['duration']}',
  //         isSuccess: true,
  //       );
  //       // Refresh profile data to update attendance status
  //       _loadUserProfile();
  //     } else {
  //       _showMessage(response['message'], isError: true);
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     _showMessage('Error al registrar la salida: $e', isError: true);
  //   }
  // }

  // Show message using SnackBar
  void _showMessage(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError
                ? Colors.red
                : (isSuccess ? Colors.green : const Color(0xFFFF8C42)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
