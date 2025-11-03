import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gym_app/services/attendance_service.dart';
import 'package:gym_app/services/user_service.dart';
import '../../utils/gym_context_helper.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final AttendanceService _attendanceService = AttendanceService();
  final UserService _userService = UserService();
  bool _hasScanned = false;
  bool _processing = false;
  bool _isCheckOut = false; // Track if we're checking out

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  // Check if user already has ongoing session (to determine check-in vs check-out)
  Future<void> _checkUserStatus() async {
    final currentUserId = _userService.getCurrentUserId();
    if (currentUserId != null) {
      try {
        final gymContext = context.gymContext; // 🔥 AGREGADO
        final sessionStatus = await _attendanceService.hasOngoingSession(
          currentUserId,
          gymContext.gymId, // 🔥 AGREGADO
        );
        if (mounted) {
          setState(() {
            _isCheckOut = sessionStatus['hasOngoing'] == true;
          });
        }
      } catch (e) {
        print('Error checking user status: $e');
      }
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  // Future<void> _processQRCode(String data) async {
  //   if (_hasScanned || _processing) return;

  //   setState(() {
  //     _processing = true;
  //   });
  //   try {
  //     // Check if the user has an ongoing session
  //     final currentUserId = _userService.getCurrentUserId();
  //     if (currentUserId == null) {
  //       _showMessage('Error: No hay usuario autenticado', isError: true);
  //       setState(() {
  //         _processing = false;
  //       });
  //       return;
  //     }

  //     final ongoingSession = await _attendanceService.hasOngoingSession(
  //       currentUserId,
  //     );
  //     final bool isCheckOut = ongoingSession['hasOngoing'] == true;

  //     // 🔥 Obtener contexto del gym
  //     final gymContext = context.gymContext;

  //     // Process check-in or check-out based on session status
  //     final response =
  //         isCheckOut
  //             ? await _attendanceService.checkOutWithQR(data)
  //             : await _attendanceService.checkInWithQR(
  //               data,
  //               gymContext.gymId,
  //               gymContext.tenantId,
  //             );

  //     if (response['success']) {
  //       // Then fetch the user's name
  //       final userId = response['userId'];
  //       final userName = await _userService.getUserName(userId);
  //       final displayName = userName ?? 'Usuario';

  //       String message;
  //       bool hasWarning = false;

  //       if (isCheckOut) {
  //         // Check-out success message with duration if available
  //         message = '¡Hasta pronto, $displayName!';
  //         if (response.containsKey('duration')) {
  //           message += '\nTiempo en el gimnasio: ${response['duration']}';
  //         }
  //       } else {
  //         // Check-in success message
  //         message = '¡Bienvenido/a, $displayName!';
  //         if (response.containsKey('warning')) {
  //           message += '\n${response['warning']}';
  //           hasWarning = true;
  //         }
  //       }

  //       _showMessage(message, isError: hasWarning);
  //       setState(() {
  //         _hasScanned = true;
  //       }); // Go back to client home after a delay
  //       Future.delayed(const Duration(seconds: 2), () {
  //         if (mounted) {
  //           Navigator.of(context).pop(true); // Return success result
  //         }
  //       });
  //     } else {
  //       // Show the error message from the response
  //       _showMessage(response['message'], isError: true);
  //       setState(() {
  //         _processing = false;
  //       });
  //     }
  //   } catch (e) {
  //     // Handle any unexpected errors
  //     _showMessage('Error: ${e.toString()}', isError: true);
  //     setState(() {
  //       _processing = false;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isCheckOut
              ? 'Escanear QR para Check-Out'
              : 'Escanear QR para Check-In',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Color(0xFFFF8C42)),
            onPressed:
                _processing || _hasScanned
                    ? null
                    : () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Color(0xFFFF8C42)),
            onPressed:
                _processing || _hasScanned
                    ? null
                    : () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Text(
              'Coloque el código QR dentro del área para registrar su entrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_processing && !_hasScanned)
                        const CircularProgressIndicator(
                          color: Color(0xFFFF8C42),
                        ),
                      if (_hasScanned)
                        Icon(
                          _isCheckOut ? Icons.exit_to_app : Icons.check_circle,
                          color: Color(0xFFFF8C42),
                          size: 80,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        _hasScanned
                            ? _isCheckOut
                                ? '¡Check-out exitoso!'
                                : '¡Check-in exitoso!'
                            : 'Procesando...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // : Stack(
                //   children: [
                //     MobileScanner(
                //       controller: _scannerController,
                //       onDetect: (capture) {
                //         final List<Barcode> barcodes = capture.barcodes;
                //         if (barcodes.isNotEmpty &&
                //             barcodes[0].rawValue != null) {
                //           _processQRCode(barcodes[0].rawValue!);
                //         }
                //       },
                //       errorBuilder: (context, error, child) {
                //         return Center(
                //           child: Column(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: [
                //               Icon(
                //                 Icons.error,
                //                 color: Colors.red.withOpacity(0.8),
                //                 size: 50,
                //               ),
                //               const SizedBox(height: 16),
                //               Text(
                //                 'Error de cámara: ${error.errorCode}',
                //                 style: TextStyle(
                //                   color: Colors.white.withOpacity(0.8),
                //                   fontSize: 16,
                //                 ),
                //               ),
                //               const SizedBox(height: 8),
                //               ElevatedButton(
                //                 onPressed:
                //                     () => _scannerController.start(),
                //                 style: ElevatedButton.styleFrom(
                //                   backgroundColor: const Color(
                //                     0xFFFF8C42,
                //                   ),
                //                   padding: const EdgeInsets.symmetric(
                //                     horizontal: 24,
                //                     vertical: 12,
                //                   ),
                //                 ),
                //                 child: const Text('Reintentar'),
                //               ),
                //             ],
                //           ),
                //         );
                //       },
                //     ),
                //     // Overlay with a centered rectangle
                //     Container(
                //       decoration: BoxDecoration(
                //         color: Colors.black.withOpacity(0.5),
                //       ),
                //       child: Center(
                //         child: Container(
                //           width: 250,
                //           height: 250,
                //           decoration: BoxDecoration(
                //             border: Border.all(
                //               color: const Color(0xFFFF8C42),
                //               width: 3,
                //             ),
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'El QR mostrado en la pantalla de Check-In contiene su identificación para registrar su asistencia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
