import 'package:flutter/material.dart';
import 'package:gym_app/widgets/log_out_button.dart';
import 'package:gym_app/services/create_collections.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: Builder(
        //   builder: (context) {
        //     return IconButton(
        //       icon: const Icon(Icons.fitness_center),
        //       onPressed: () {
        //         Scaffold.of(context).openDrawer();
        //       },
        //     );
        //   },
        // ),
        title: const Text('Gym App'),
        actions: const [LogoutButton()],
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                // Update the state of the app.
                // ...

                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                // Update the state of the app.
                // ...

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido a tu entrenamiento 💪',
              style: TextStyle(fontSize: 20),
            ),
            // const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await createFakeGymData();
              },
              child: const Text('Crear Datos Fake'),
            ),
          ],
        ),
      ),
    );
  }
}
