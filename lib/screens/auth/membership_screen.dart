import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({Key? key}) : super(key: key);

  String getImageForMembership(String title) {
    switch (title.toLowerCase()) {
      case 'plan diario':
        return 'assets/memberships/basic.jpg';
      case 'plan mensual':
        return 'assets/memberships/medium.jpg';
      case 'plan anual':
        return 'assets/memberships/premium.jpg';
      default:
        return 'assets/memberships/basic.jpg';
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Membresías',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('memberships').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Algo salió mal',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C42)),
            );
          }

          final memberships =
              snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return MembershipData(
                  title: data['name'] ?? '',
                  price: data['price']?.toString() ?? '0.0',
                  features: [
                    'Acceso ${data['durationDays']} días',
                    data['description'] ?? '',
                    'Acceso a todas las máquinas',
                    'Asesoramiento personalizado',
                    'Acceso a clases grupales',
                  ],
                  imageUrl: getImageForMembership(data['name'] ?? ''),
                );
              }).toList();

          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: CarouselSlider.builder(
              itemCount: memberships.length,
              itemBuilder: (context, index, realIndex) {
                return MembershipCard(membershipData: memberships[index]);
              },
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height * 0.75,
                viewportFraction: 0.85,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                initialPage: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MembershipData {
  final String title;
  final String price;
  final List<String> features;
  final String imageUrl;

  MembershipData({
    required this.title,
    required this.price,
    required this.features,
    required this.imageUrl,
  });
}

class MembershipCard extends StatelessWidget {
  final MembershipData membershipData;

  const MembershipCard({Key? key, required this.membershipData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(membershipData.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              membershipData.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${membershipData.price}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '/mo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ...membershipData.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFFF8C42),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
