import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity/connectivity.dart';
import 'ScreenSplash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Vérification de la connexion Internet
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    runApp(const NoInternetApp());
    return;
  }

  try {
    // Initialisation Firebase avec les options Web intégrées
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCnh_ASebfWCdb1Fz7rrG0GMLCRz8g97EE",
          authDomain: "gestionpaie-283d1.firebaseapp.com",
          projectId: "gestionpaie-283d1",
          storageBucket: "gestionpaie-283d1.appspot.com",
          messagingSenderId: "948906083663",
          appId: "1:948906083663:web:aa1c27d6f730433d69b13a",
          measurementId: "G-D3X7VLBDPH"
      ),
    );
    print("Firebase initialisé avec succès !");
  } catch (e) {
    print("Erreur d'initialisation de Firebase : $e");
  }

  runApp(const AKM());
}

class AKM extends StatelessWidget {
  const AKM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKM-Ammortissement',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScreenSplash(),
    );
  }
}

// Classe affichée en cas de connexion Internet absente
class NoInternetApp extends StatelessWidget {
  const NoInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pas de connexion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const NoInternetScreen(),
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur de connexion'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Pas de connexion Internet",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                var connectivityResult = await Connectivity().checkConnectivity();
                if (connectivityResult != ConnectivityResult.none) {
                  // Redémarre l'application
                  main();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Toujours pas de connexion Internet !"),
                    ),
                  );
                }
              },
              child: const Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }
}
