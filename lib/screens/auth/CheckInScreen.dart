import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/widgets/DesactivateTotenModeButton.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gym_app/services/attendance_service.dart';
import 'package:gym_app/services/user_service.dart';
import '../../utils/gym_context_helper.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final AttendanceService _attendanceService = AttendanceService();
  final UserService _userService = UserService();
  final int pinLength = 4;
  String _pin = '';
  List<String> _displayPin = [];
  String? userId;
  // Mode variables for check-in/check-out toggle
  bool _isCheckOutMode = false;

  // Animation controller for pressed button effect
  late AnimationController _animationController;
  String? _lastPressedButton;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  void _addDigit(String digit) {
    if (_pin.length < pinLength) {
      setState(() {
        _pin += digit;
        _displayPin.add('•');
        _pinController.text = _pin;

        // Set last pressed button for animation
        _lastPressedButton = digit;
      });

      // Animate the button press
      _animationController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _lastPressedButton = null;
          });
        }
      });

      // Auto submit when pin is complete
      if (_pin.length == pinLength) {
        _handlePinSubmit();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _displayPin.removeLast();
        _pinController.text = _pin;
      });
    }
  }

  void _clearPin() {
    setState(() {
      _pin = '';
      _displayPin.clear();
      _pinController.text = '';
    });
  }

  Future<void> _handlePinSubmit() async {
    if (_pin.length < pinLength) {
      _showMessage("El PIN debe tener $pinLength dígitos.");
      return;
    }
    try {
      final gymContext = context.gymContext;
      // Check in or out based on the current mode
      final response =
          _isCheckOutMode
              ? await _attendanceService.checkOutWithPin(_pin, _showMessage)
              : await _attendanceService.checkInWithPin(
                _pin,
                gymContext.gymId,
                gymContext.tenantId,
                _showMessage,
              );

      if (!response['success']) {
        _showMessage(response['message']);
        _clearPin();
        return;
      }

      // Get the userId from the response
      final userId = response['userId']; // Then fetch the user's name
      final userName = await _userService.getUserName(userId);
      final displayName =
          userName ?? 'Usuario'; // Show success animation with user's name

      // Different messages for check-in vs check-out
      String messageText;
      Color backgroundColor = Colors.green;
      IconData icon = Icons.check_circle;

      if (_isCheckOutMode) {
        // Check-out success message with duration if available
        messageText = "¡Hasta pronto, $displayName!";
        if (response.containsKey('duration')) {
          messageText += "\nTiempo en el gimnasio: ${response['duration']}";
        }
        icon = Icons.exit_to_app;
      } else {
        // Check-in success message with warning if available
        messageText = "¡Bienvenido/a, $displayName!";
        if (response.containsKey('warning')) {
          messageText += "\n${response['warning']}";
          backgroundColor = Colors.orange;
        }
        icon = Icons.login;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  messageText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      );

      // Clear the PIN after success
      _clearPin();
    } catch (e) {
      // // Check if the error is due to already checked in today
      // if (e.toString().contains('Ya registraste tu asistencia hoy')) {
      //   _showMessage("Ya registraste tu asistencia hoy.");
      // } else {
      //   _showMessage("Error al verificar PIN: ${e.toString()}");
      // }
      _clearPin();
    }
  } // Function to get current user's ID using the service

  Future<void> _fetchCurrentUserId() async {
    try {
      final String? currentUserId = _userService.getCurrentUserId();

      if (currentUserId != null) {
        setState(() {
          userId = currentUserId;
        });
      } else {
        _showMessage("No hay usuario autenticado");
      }
    } catch (e) {
      _showMessage("Error al obtener usuario: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  // Only using square button builders

  // Square button builders
  Widget _buildSquareButton(String number, double size) {
    final isPressed = _lastPressedButton == number;

    return GestureDetector(
      onTap: () => _addDigit(number),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale =
              isPressed ? 1.0 - (_animationController.value * 0.1) : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  8,
                ), // Square with slightly rounded corners
                color: Colors.transparent,
                border: Border.all(color: const Color(0xFFFF8C42), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFF8C42,
                    ).withOpacity(isPressed ? 0.2 : 0.3),
                    spreadRadius: isPressed ? 0 : 1,
                    blurRadius: isPressed ? 2 : 4,
                    offset: isPressed ? const Offset(0, 1) : const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: size * 0.5, // Larger responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSquareFunctionButton(
    IconData icon,
    double size,
    VoidCallback onPressed,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        onPressed();
        _animationController.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                8,
              ), // Square with slightly rounded corners
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFFFF8C42), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C42).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: size * 0.5, // Larger responsive icon size
                color: const Color(0xFFFF8C42),
              ),
            ),
          );
        },
      ),
    );
  }

  // No QR code scanning functionality  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isSmallScreen = isLandscape ? screenHeight < 400 : screenWidth < 400;
    final isMediumScreen =
        isLandscape
            ? screenHeight >= 400 && screenHeight < 600
            : screenWidth >= 400 && screenWidth < 600;

    // Responsive sizing - use smaller dimension for consistent sizing
    final buttonSizeBase = isLandscape ? screenHeight : screenWidth;
    final buttonSize =
        isSmallScreen
            ? buttonSizeBase * (isLandscape ? 0.12 : 0.15)
            : isMediumScreen
            ? buttonSizeBase * (isLandscape ? 0.10 : 0.12)
            : buttonSizeBase * (isLandscape ? 0.07 : 0.08);

    final pinBoxSize =
        isSmallScreen
            ? buttonSizeBase * (isLandscape ? 0.07 : 0.08)
            : isMediumScreen
            ? buttonSizeBase * (isLandscape ? 0.05 : 0.06)
            : buttonSizeBase * (isLandscape ? 0.04 : 0.05);

    final titleFontSize =
        isSmallScreen
            ? 32.0
            : isMediumScreen
            ? 42.0
            : 60.0;
    final subtitleFontSize =
        isSmallScreen
            ? 14.0
            : isMediumScreen
            ? 18.0
            : 24.0;

    final buttonSpacing =
        isSmallScreen
            ? 10.0
            : isMediumScreen
            ? 15.0
            : 25.0;
    final rowSpacing =
        isSmallScreen
            ? 8.0
            : isMediumScreen
            ? 10.0
            : 15.0;
    final pinBoxMargin =
        isSmallScreen
            ? 8.0
            : isMediumScreen
            ? 12.0
            : 20.0;

    // QR code container sizing - use the smaller screen dimension for better layout
    final qrMarginH =
        isSmallScreen
            ? (isLandscape ? screenHeight : screenWidth) * 0.05
            : isMediumScreen
            ? (isLandscape ? screenHeight : screenWidth) * 0.08
            : (isLandscape ? screenHeight : screenWidth) * 0.12;

    final qrHeight =
        isLandscape
            ? screenHeight *
                0.4 // Taller in landscape to maintain proportions
            : (isSmallScreen
                ? screenHeight * 0.20
                : isMediumScreen
                ? screenHeight * 0.22
                : screenHeight * 0.25);

    final qrImageSize =
        isLandscape
            ? screenHeight *
                0.35 // Slightly smaller than container in landscape
            : (isSmallScreen
                ? screenHeight * 0.15
                : isMediumScreen
                ? screenHeight * 0.17
                : screenHeight * 0.20);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, const Color(0xFF212121)],
                  ),
                ),
              ),

              // Main content in a scrollable container for small screens
              isSmallScreen
                  ? SingleChildScrollView(
                    child: _buildMainContent(
                      screenWidth,
                      screenHeight,
                      isSmallScreen,
                      titleFontSize,
                      subtitleFontSize,
                      qrMarginH,
                      qrHeight,
                      qrImageSize,
                      buttonSize,
                      pinBoxSize,
                      pinBoxMargin,
                      buttonSpacing,
                      rowSpacing,
                    ),
                  )
                  : _buildMainContent(
                    screenWidth,
                    screenHeight,
                    isSmallScreen,
                    titleFontSize,
                    subtitleFontSize,
                    qrMarginH,
                    qrHeight,
                    qrImageSize,
                    buttonSize,
                    pinBoxSize,
                    pinBoxMargin,
                    buttonSpacing,
                    rowSpacing,
                  ),

              // Botón para salir del modo toten
              Positioned(
                top: 16,
                right: 16,
                child: DesactivateTotenModeButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
    double titleFontSize,
    double subtitleFontSize,
    double qrMarginH,
    double qrHeight,
    double qrImageSize,
    double buttonSize,
    double pinBoxSize,
    double pinBoxMargin,
    double buttonSpacing,
    double rowSpacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo and Header area
          SizedBox(height: screenHeight * 0.01),
          Image.asset('assets/gym_logo.png', height: screenHeight * 0.06),
          const SizedBox(height: 8),

          // Title
          Text(
            _isCheckOutMode ? 'CHECK-OUT' : 'CHECK-IN',
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _isCheckOutMode
                ? 'Ingrese su PIN o escanee el código QR para salir'
                : 'Ingrese su PIN o escanee el código QR desde el App',
            style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize),
            textAlign: TextAlign.center,
          ),

          // Toggle button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCheckOutMode = !_isCheckOutMode;
                  _clearPin();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isCheckOutMode
                        ? Colors.redAccent
                        : const Color(0xFFFF8C42),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 20,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: Icon(
                _isCheckOutMode ? Icons.logout : Icons.login,
                color: Colors.white,
                size: isSmallScreen ? 16 : 20,
              ),
              label: Text(
                _isCheckOutMode ? "Cambiar a Entrada" : "Cambiar a Salida",
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // QR Code Area
          Container(
            margin: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015,
              horizontal: qrMarginH,
            ),
            height: qrHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFF8C42), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C42).withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: qrImageSize,
                height: qrImageSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: userId ?? 'Usuario no identificado',
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFFFF8C42),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (ctx, err) {
                    return const Center(
                      child: Text(
                        "Error al generar el QR",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // PIN Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(pinLength, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: pinBoxMargin),
                  width: pinBoxSize,
                  height: pinBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFFF8C42),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C42).withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        index < _displayPin.length
                            ? Text(
                              "•",
                              style: TextStyle(
                                fontSize: pinBoxSize * 0.6,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF8C42),
                              ),
                            )
                            : null,
                  ),
                );
              }),
            ],
          ),

          SizedBox(height: screenHeight * 0.02),

          // Number Pad
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareButton('1', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('2', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('3', buttonSize),
                ],
              ),
              SizedBox(height: rowSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareButton('4', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('5', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('6', buttonSize),
                ],
              ),
              SizedBox(height: rowSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareButton('7', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('8', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('9', buttonSize),
                ],
              ),
              SizedBox(height: rowSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSquareFunctionButton(
                    Icons.backspace,
                    buttonSize,
                    _removeDigit,
                    const Color(0xFFFF8C42),
                  ),
                  SizedBox(width: buttonSpacing),
                  _buildSquareButton('0', buttonSize),
                  SizedBox(width: buttonSpacing),
                  _buildSquareFunctionButton(
                    Icons.clear,
                    buttonSize,
                    _clearPin,
                    const Color(0xFFFF8C42),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }
}
