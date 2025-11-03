import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/screens/client/client_workouts_screen.dart';
import 'package:gym_app/services/subscription_service.dart';
import 'package:gym_app/services/membership_service.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import '../../../utils/gym_context_helper.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _subscriptionService = SubscriptionService();
  final _membershipService = MembershipService();

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return userData.data()?['name'] ?? 'Cliente';
    }
    return 'Cliente';
  }

  Future<Map<String, dynamic>> _getMembershipInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'isValid': false,
        'membershipName': 'Sin membresía',
        'endDate': '',
        'daysRemaining': 0,
      };
    }

    try {
      // 🔥 Obtener contexto del gym
      final gymContext = context.gymContext;

      final subscription = await _subscriptionService
          .getActiveSubscriptionForUser(user.uid, gymContext.gymId);
      if (subscription == null) {
        return {
          'isValid': false,
          'membershipName': 'Sin membresía',
          'endDate': '',
          'daysRemaining': 0,
        };
      }

      final membership = await _membershipService.getMembershipById(
        subscription.membershipId,
      );
      final daysRemaining = await _subscriptionService
          .getDaysRemainingInSubscription(user.uid, gymContext.gymId);
      final endDate = subscription.endDate;

      return {
        'isValid': daysRemaining > 0,
        'membershipName': membership?.name ?? 'Membresía',
        'endDate': '${endDate.day}/${endDate.month}/${endDate.year}',
        'daysRemaining': daysRemaining,
      };
    } catch (e) {
      print('Error getting membership info: $e');
      return {
        'isValid': false,
        'membershipName': 'Error al cargar membresía',
        'endDate': '',
        'daysRemaining': 0,
      };
    }
  }

  Widget _buildMembershipCard(Map<String, dynamic> membershipInfo) {
    final isValid = membershipInfo['isValid'] as bool;
    final membershipName = membershipInfo['membershipName'] as String;
    final endDate = membershipInfo['endDate'] as String;
    final daysRemaining = membershipInfo['daysRemaining'] as int;

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/memberships/premium.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  membershipName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isValid ? 'Activa' : 'Inactiva',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (endDate.isNotEmpty)
                  Text(
                    'Vence: $endDate',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                if (daysRemaining > 0)
                  Text(
                    'Días restantes: $daysRemaining',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
              ],
            ),
          ],
        ),
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
        title: FutureBuilder<String>(
          future: _getUserName(),
          builder: (context, snapshot) {
            return Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    // ignore: use_build_context_properly
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hola, ${snapshot.data ?? 'Cargando...'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // const ActivateTotenModeButton(),
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFFF8C42)),
            onPressed: () {
              Navigator.pushNamed(context, '/user-profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu progreso',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              _buildCard('Progreso', 'assets/workouts/full_body.jpg', () {
                Navigator.pushNamed(context, AppRoutes.clientProgress);
              }),
              const SizedBox(height: 32),
              const Text(
                'Planes',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                'Planes de\nEntrenamiento',
                'assets/memberships/medium.jpg',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientWorkoutsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Membresías',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                'Ver Planes de\nMembresía',
                'assets/memberships/premium.jpg',
                () {
                  Navigator.pushNamed(context, AppRoutes.memberships);
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Estado de Membresía',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>>(
                future: _getMembershipInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF8C42),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error al cargar la membresía',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return _buildMembershipCard(
                    snapshot.data ??
                        {
                          'isValid': false,
                          'membershipName': 'Error',
                          'endDate': '',
                          'daysRemaining': 0,
                        },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
