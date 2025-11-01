import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:gym_app/services/membership_service.dart';
import 'package:gym_app/models/membership.dart';

class SubscriptionRenewalScreen extends StatefulWidget {
  const SubscriptionRenewalScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionRenewalScreen> createState() => _SubscriptionRenewalScreenState();
}

class _SubscriptionRenewalScreenState extends State<SubscriptionRenewalScreen> {
  final _subscriptionService = SubscriptionService();
  final _membershipService = MembershipService();
  List<Map<String, dynamic>> _clientsData = [];
  List<Membership> _memberships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Cargar membresías disponibles
      _memberships = await _membershipService.getAllMemberships();
      
      // Obtener todos los clientes
      final clientsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('roles', arrayContains: {'id': 'cli', 'name': 'Cliente'})
          .get();

      final clientsData = await Future.wait(
        clientsQuery.docs.map((doc) async {
          final userData = doc.data();
          final userId = doc.id;

          // Obtener días restantes de membresía
          final daysRemaining = await _subscriptionService.getDaysRemainingInSubscription(userId);
          
          // Obtener membresía actual
          String membershipName = 'Sin membresía';
          if (userData['membershipId'] != null) {
            final membershipDoc = await FirebaseFirestore.instance
                .collection('memberships')
                .doc(userData['membershipId'])
                .get();
            if (membershipDoc.exists) {
              membershipName = membershipDoc.data()?['name'] ?? 'Sin membresía';
            }
          }

          return {
            'userId': userId,
            'name': '${userData['name']} ${userData['surname1']} ${userData['surname2']}',
            'membershipName': membershipName,
            'daysRemaining': daysRemaining,
            'currentMembershipId': userData['membershipId'],
          };
        }),
      );

      setState(() {
        _clientsData = clientsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRenewalDialog(Map<String, dynamic> client) async {
    String? selectedMembershipId;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Renovar Membresía',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${client['name']}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seleccionar nueva membresía:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF8C42)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF8C42)),
                  ),
                ),
                items: _memberships.map((membership) {
                  return DropdownMenuItem<String>(
                    value: membership.id,
                    child: Text(
                      '${membership.name} - \$${membership.price} (${membership.durationDays} días)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedMembershipId = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Renovar',
                style: TextStyle(color: Color(0xFFFF8C42)),
              ),
              onPressed: () async {
                if (selectedMembershipId != null) {
                  Navigator.of(context).pop(selectedMembershipId);
                }
              },
            ),
          ],
        );
      },
    ).then((selectedId) async {
      if (selectedId != null) {
        try {
          final selectedMembership = _memberships.firstWhere(
            (m) => m.id == selectedId
          );
          
          final now = DateTime.now();
          
          // Actualizar membresía del usuario
          await FirebaseFirestore.instance
              .collection('users')
              .doc(client['userId'])
              .update({
            'membershipId': selectedId,
          });

          // Crear nueva suscripción
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .add({
            'userId': client['userId'],
            'membershipId': selectedId,
            'startDate': now,
            'endDate': now.add(Duration(days: selectedMembership.durationDays)),
            'status': 'active',
            'type': 'regular',
            'paymentAmount': selectedMembership.price,
            'paymentDate': now,
            'createdAt': now,
          });

          // Actualizar la lista
          await _loadData();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membresía renovada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al renovar membresía: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Renovar Suscripciones',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clientsData.length,
              itemBuilder: (context, index) {                final client = _clientsData[index];
                final daysRemaining = client['daysRemaining'] as int;
                final bool isExpired = daysRemaining < 1; // Cambiar a < 1 para considerar que 1 día aún es válido

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white.withOpacity(0.05),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      client['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Membresía actual: ${client['membershipName']}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isExpired
                              ? 'MEMBRESÍA VENCIDA'
                              : 'Días restantes: $daysRemaining',
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.grey[400],
                            fontWeight: isExpired ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _showRenewalDialog(client),
                      child: const Text(
                        'Renovar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
