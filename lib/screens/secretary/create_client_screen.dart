import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../../services/user_service.dart';
import '../../../services/membership_service.dart';
import '../../../models/membership.dart';
import '../../../utils/gym_context_helper.dart';
import 'weight_selection_screen.dart';
import 'height_selection_screen.dart';

class CreateClientScreen extends StatefulWidget {
  const CreateClientScreen({Key? key}) : super(key: key);

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _membershipService = MembershipService();

  String _name = '';
  String _surname1 = '';
  String _surname2 = '';
  String _phone = '';
  String _email = '';
  String _password = '';
  String _height = '';
  String _weight = '';
  String? _selectedMembershipId;
  DateTime? _birthDate;
  late String _pin;

  bool _isLoading = false;
  List<Membership> _memberships = [];
  bool _loadingMemberships = true;

  @override
  void initState() {
    super.initState();
    // Generate PIN automatically
    _pin =
        (1000 + DateTime.now().millisecond + DateTime.now().microsecond % 9000)
            .toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMemberships();
    });
  }

  Future<void> _loadMemberships() async {
    try {
      // 🔥 Obtener contexto del gym
      final gymContext = context.gymContext;
      final memberships = await _membershipService.getAllMemberships(
        gymContext.gymId,
      );
      setState(() {
        _memberships = memberships;
        _loadingMemberships = false;
      });
    } catch (e) {
      print('Error loading memberships: $e');
      setState(() {
        _loadingMemberships = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembershipId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione una membresía'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione la fecha de nacimiento'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // 🔥 Obtener contexto del gym
        final gymContext = context.gymContext;

        // Roles fijos para Cliente
        final roles = [
          {'id': 'cli', 'name': 'Cliente'},
        ];

        await _userService.createUser(
          gymId: gymContext.gymId,
          tenantId: gymContext.tenantId,
          email: _email.trim(),
          password: _password,
          name: _name.trim(),
          roles: roles,
          surname1: _surname1.trim(),
          surname2: _surname2.trim(),
          phone: _phone.trim(),
        );

        // Obtener el ID del usuario recién creado
        final newUser = auth.FirebaseAuth.instance.currentUser;
        if (newUser != null) {
          final userId = newUser.uid;
          // Actualizar altura, peso, membresía y PIN en Firestore
          final heightVal = int.tryParse(_height) ?? 0;
          final weightVal = int.tryParse(_weight) ?? 0;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'height': heightVal,
                'weight': weightVal,
                'membershipId': _selectedMembershipId,
                'pin': _pin,
                'dateOfBirth': _birthDate!.toIso8601String().split('T')[0],
                'createdAt': DateTime.now().toIso8601String().split('T')[0],
              });

          // Crear suscripción para el usuario
          final selectedMembership = _memberships.firstWhere(
            (m) => m.id == _selectedMembershipId,
          );
          final now = DateTime.now();
          await FirebaseFirestore.instance.collection('subscriptions').add({
            'userId': userId,
            'membershipId': _selectedMembershipId,
            'startDate': Timestamp.fromDate(now),
            'endDate': Timestamp.fromDate(
              now.add(Duration(days: selectedMembership.durationDays)),
            ),
            'status': 'active',
            'type': 'regular',
            'paymentAmount': selectedMembership.price,
            'paymentDate': Timestamp.fromDate(now),
            'createdAt': Timestamp.fromDate(now),
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente creado exitosamente.\nPIN asignado: $_pin'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'Error al crear cliente';
        final msg = e.toString();
        if (msg.contains('email-already-in-use')) {
          errorMessage = 'El correo electrónico ya está en uso';
        } else if (msg.contains('weak-password')) {
          errorMessage = 'La contraseña es muy débil';
        } else if (msg.contains('invalid-email')) {
          errorMessage = 'El correo electrónico no es válido';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Cliente',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nombre
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Nombre *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF8C42)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                        onSaved: (value) => _name = value ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Primer Apellido
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Primer Apellido *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF8C42)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el primer apellido';
                          }
                          return null;
                        },
                        onSaved: (value) => _surname1 = value ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Segundo Apellido
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Segundo Apellido *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF8C42)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el segundo apellido';
                          }
                          return null;
                        },
                        onSaved: (value) => _surname2 = value ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Fecha de Nacimiento
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFFF8C42),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF2A2A2A),
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor: const Color(
                                    0xFF1A1A1A,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              _birthDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha de Nacimiento *',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                          ),
                          child: Text(
                            _birthDate == null
                                ? 'Seleccionar fecha'
                                : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color:
                                  _birthDate == null
                                      ? Colors.grey[400]
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Teléfono *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF8C42)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el teléfono';
                          }
                          return null;
                        },
                        onSaved: (value) => _phone = value ?? '',
                      ),
                      const SizedBox(height: 16), // Altura
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const HeightSelectionScreen(),
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() {
                              _height = result['height'].toString();
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Altura *',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                          ),
                          child: Text(
                            _height.isEmpty
                                ? 'Seleccionar altura'
                                : '$_height cm',
                            style: TextStyle(
                              color:
                                  _height.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Peso
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const WeightSelectionScreen(),
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() {
                              _weight = result['weight'].toString();
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Peso *',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                          ),
                          child: Text(
                            _weight.isEmpty
                                ? 'Seleccionar peso'
                                : '$_weight kg',
                            style: TextStyle(
                              color:
                                  _weight.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Correo electrónico
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF8C42)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el correo';
                          }
                          if (!value.contains('@')) {
                            return 'Por favor ingrese un correo válido';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Contraseña *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF8C42)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                        onSaved: (value) => _password = value ?? '',
                      ),
                      const SizedBox(height: 24),

                      // Selector de Membresía
                      if (_loadingMemberships)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF8C42),
                            ),
                          ),
                        )
                      else if (_memberships.isEmpty)
                        const Text(
                          'No hay membresías disponibles',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedMembershipId,
                          decoration: InputDecoration(
                            labelText: 'Membresía *',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF8C42)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF1A1A1A),
                          items:
                              _memberships.map((membership) {
                                return DropdownMenuItem<String>(
                                  value: membership.id,
                                  child: Text(
                                    '${membership.name} - \$${membership.price} (${membership.durationDays} días)',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMembershipId = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor seleccione una membresía';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Crear Cliente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
