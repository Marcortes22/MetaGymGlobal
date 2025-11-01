import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      color: Colors.red,
      onPressed: () async {
        try {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error cerrando sesión: $e')));
        }
      },
    );
  }
}
