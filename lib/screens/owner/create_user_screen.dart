import 'package:flutter/material.dart';
import '../../../services/user_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  String _name = '';
  String _email = '';
  String _password = '';
  Set<String> _selectedRoles = {'coa'}; // Usando Set para roles múltiples
  bool _isLoading = false;
  String _surname1 = '';
  String _surname2 = '';
  String _phone = '';

  final _roles = [
    {
      'value': 'own',
      'label': 'Administrador',
      'icon': Icons.admin_panel_settings_outlined,
    },
    {'value': 'sec', 'label': 'Secretaria', 'icon': Icons.support_agent},
    {'value': 'coa', 'label': 'Entrenador', 'icon': Icons.fitness_center},
  ];

  Color _getRoleColor(String role) {
    switch (role) {
      case 'own':
        return Colors.purple;
      case 'coa':
        return Colors.green;
      case 'sec':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione al menos un rol'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // Convertir los roles seleccionados al formato requerido
        List<Map<String, String>> roles =
            _selectedRoles.map((role) {
              String roleName =
                  _roles.firstWhere((r) => r['value'] == role)['label']
                      as String;
              return {'id': role, 'name': roleName};
            }).toList();

        await _userService.createUser(
          email: _email.trim(),
          password: _password,
          name: _name.trim(),
          roles: roles,
          surname1: _surname1.trim(),
          surname2: _surname2.trim(),
          phone: _phone.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Error al crear usuario';
          if (e.toString().contains('email-already-in-use')) {
            errorMessage = 'El correo electrónico ya está en uso';
          } else if (e.toString().contains('weak-password')) {
            errorMessage = 'La contraseña es muy débil';
          } else if (e.toString().contains('invalid-email')) {
            errorMessage = 'El correo electrónico no es válido';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
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
          'Crear Usuario del Staff',
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
                      const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Seleccione el rol *',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ),
                    ..._roles.map((role) {
                      final bool isSelected = _selectedRoles.contains(
                        role['value'],
                      );
                      return InkWell(
                        onTap: () {
                          setState(() {
                            final roleValue = role['value'] as String;
                            if (isSelected) {
                              _selectedRoles.remove(roleValue);
                            } else {
                              _selectedRoles.add(roleValue);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getRoleColor(
                                  role['value'] as String,
                                ).withOpacity(isSelected ? 1 : 0.2),
                                child: Icon(
                                  role['icon'] as IconData,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : _getRoleColor(
                                            role['value'] as String,
                                          ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                role['label'] as String,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: _getRoleColor(role['value'] as String),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
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
                          'Crear Usuario',
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
