import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_app/services/profile_service.dart';
import 'package:gym_app/screens/shared/user_profile_screen.dart';

class AllAttendanceScreen extends StatefulWidget {
  const AllAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AllAttendanceScreen> createState() => _AllAttendanceScreenState();
}

class _AllAttendanceScreenState extends State<AllAttendanceScreen> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  late DateTime now;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day); // 00:00
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _profileService.getAllUsersAttendance(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando asistencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF8C42),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          0,
          0,
          0,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _loadAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Registro de Asistencia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Color(0xFFFF8C42)),
            onPressed: _selectDateRange,
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF8C42)),
            onPressed: _loadAttendanceData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Período: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: const Color(0xFF2A2A2A),
            child: const Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Fecha',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Usuario',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Entrada',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Salida',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF8C42),
                        ),
                      ),
                    )
                    : _attendanceRecords.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay registros de asistencia',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceRecords[index];
                        return _buildAttendanceRow(record);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(Map<String, dynamic> record) {
    return InkWell(
      onTap: () {
        // Navigate to user profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UserProfileScreen(
                  userId: record['userId'],
                  isAdminView: true,
                ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                record['formattedDate'],
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text(
                record['userName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                record['formattedCheckInTime'],
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                record['formattedCheckOutTime'],
                style: TextStyle(
                  color:
                      record['formattedCheckOutTime'] == 'N/A'
                          ? Colors.white38
                          : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
