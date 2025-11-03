import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/screens/secretary/create_client_screen.dart';
import 'package:gym_app/services/user_service.dart';
import '../../../models/user.dart';
import '../../../utils/gym_context_helper.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({Key? key}) : super(key: key);

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _userService = UserService();
  late Future<List<User>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  void _loadClients() {
    _clientsFuture = _getClients();
  }

  Future<List<User>> _getClients() async {
    // 🔥 Obtener contexto del gym
    final gymContext = context.gymContext;

    // Obtener usuarios que son clientes
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('roles', arrayContains: {'id': 'cli', 'name': 'Cliente'})
            .get();

    final users =
        querySnapshot.docs.map((doc) {
          final data = doc.data();
          return User(
            gymId: gymContext.gymId,
            tenantId: gymContext.tenantId,
            id: doc.id,
            userId: data['user_id'] ?? '',
            name: data['name'] ?? '',
            surname1: data['surname1'] ?? '',
            surname2: data['surname2'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'] ?? '',
            pin: data['pin'],
            roles: List<Map<String, String>>.from(
              data['roles']?.map((r) => Map<String, String>.from(r)) ?? [],
            ),
            height: data['height'] ?? 0,
            weight: data['weight'] ?? 0,
            dateOfBirth: data['dateOfBirth'] ?? '',
            membershipId: data['membershipId'],
            profilePictureUrl: data['profilePictureUrl'],
          );
        }).toList();

    return users;
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Confirmar Eliminación',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              '¿Estás seguro que deseas eliminar a ${user.name} ${user.surname1}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _userService.deleteUser(user.id);
                    if (!mounted) return;
                    Navigator.pop(context);
                    setState(() {
                      _loadClients(); // Recargar la lista
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente eliminado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(User user) async {
    String newName = user.name;
    String newPhone = user.phone;
    String newHeight = user.height.toString();
    String newWeight = user.weight.toString();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Editar Cliente',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: user.name,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF8C42)),
                      ),
                    ),
                    onChanged: (value) => newName = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF8C42)),
                      ),
                    ),
                    onChanged: (value) => newPhone = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.height.toString(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Altura (cm)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF8C42)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => newHeight = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.weight.toString(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Peso (kg)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF8C42)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => newWeight = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // 🔥 Obtener contexto del gym
                    final gymContext = context.gymContext;

                    final updatedUser = User(
                      gymId: gymContext.gymId,
                      tenantId: gymContext.tenantId,
                      id: user.id,
                      userId: user.userId,
                      name: newName,
                      surname1: user.surname1,
                      surname2: user.surname2,
                      email: user.email,
                      phone: newPhone,
                      pin: user.pin,
                      roles: user.roles,
                      height: int.tryParse(newHeight) ?? user.height,
                      weight: int.tryParse(newWeight) ?? user.weight,
                      dateOfBirth: user.dateOfBirth,
                      membershipId: user.membershipId,
                      profilePictureUrl: user.profilePictureUrl,
                    );
                    await _userService.updateUser(updatedUser);
                    if (!mounted) return;
                    Navigator.pop(context);
                    setState(() {
                      _loadClients(); // Recargar la lista
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente actualizado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: Color(0xFFFF8C42)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Clientes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: FutureBuilder<List<User>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final clients = snapshot.data ?? [];

          if (clients.isEmpty) {
            return const Center(
              child: Text(
                'No hay clientes registrados',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF8C42).withOpacity(0.1),
                    child: Text(
                      client.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF8C42),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${client.name} ${client.surname1} ${client.surname2}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        client.email,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tel: ${client.phone}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFFFF8C42)),
                    color: const Color(0xFF2A2A2A),
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              title: const Text(
                                'Editar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              horizontalTitleGap: 8,
                              onTap: () {
                                Navigator.pop(context);
                                _showEditDialog(client);
                              },
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              title: const Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              horizontalTitleGap: 8,
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(client);
                              },
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF8C42),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateClientScreen()),
          );
          if (result == true) {
            setState(() {
              _loadClients(); // Recargar la lista después de crear un nuevo cliente
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
