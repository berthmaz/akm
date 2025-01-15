import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashBoardUser extends StatelessWidget {
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 36), // Affichage de l'icône
              const SizedBox(width: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchUserStats() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Utilisateurs').get();

    int totalUsers = 0;
    int admins = 0;
    int nonAdmins = 0;
    int blockedUsers = 0;
    int activeUsers = 0;
    int superAdmin = 0;

    Set<String> processedUserIds = {}; // Utilisé pour éviter les doublons

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      if (!processedUserIds.add(doc.id)) {
        // Ignorer les doublons (basé sur doc.id ou userId)
        continue;
      }

      totalUsers++;

      if (data['administrateur'] == true) {
        admins++;
      } else {
        nonAdmins++;
      }

      if (data['superadministrateur'] == true) {
        superAdmin++;
      }

      if (data['bloquer'] == true) {
        blockedUsers++;
      } else {
        activeUsers++;
      }
    }

    return {
      'totalUsers': totalUsers,
      'admins': admins,
      'nonAdmins': nonAdmins,
      'blockedUsers': blockedUsers,
      'activeUsers': activeUsers,
      'superAdmin': superAdmin,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Couleur blanche
      appBar: AppBar(
        automaticallyImplyLeading: false, // Suppression du bouton retour
        title: const Text(
          'Tableau de bord utilisateurs',
          style: TextStyle(
            fontSize: 20, // Taille réduite pour un effet plus équilibré
            fontWeight: FontWeight.bold, // Poids plus marqué
            color: Colors.blueGrey, // Couleur plus professionnelle
            letterSpacing: 2.5, // Espacement des lettres légèrement augmenté
            shadows: [
              Shadow(
                offset: Offset(2, 2), // Ombre légère et subtile
                blurRadius: 8, // Réduction du flou de l'ombre pour un effet plus fin
                color: Colors.black26, // Ombre plus douce pour un effet subtil
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4, // Légère élévation pour un effet moderne
      ),

      body: Row(
        children: [
// Menu latéral pour écran 1080px
          Container(
            color: Colors.blueGrey,
            width: 280,
            height: 1080,// Largeur ajustée pour un écran plus large
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: fetchUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var stats = snapshot.data!;
                      return Column(
                        children: [
                          // Total Users Label
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.group_add, color: Colors.yellow, size: 36),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${stats['totalUsers']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32, // Augmenté pour meilleure lisibilité
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Utilisateurs',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 1,
                            color: Colors.white30,
                            height: 16,
                          ),

                          // Admins Label
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, color: Colors.yellow, size: 36),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${stats['admins']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Administrateurs',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 1,
                            color: Colors.white30,
                            height: 16,
                          ),

                          // Non-Admins Label
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.supervised_user_circle, color: Colors.yellow, size: 36),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${stats['nonAdmins']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Utilisateurs',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            thickness: 1,
                            color: Colors.white30,
                            height: 16,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Section principale
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: fetchUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var stats = snapshot.data!;
                      return Column(
                        children: [
                          // Cartes secondaires
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Super administrateur',
                                  '${stats['superAdmin']}',
                                  Colors.purple,
                                  Icons.add_moderator_outlined, // Icône pour hommes
                                ),
                              ),
                              const SizedBox(width: 12),

                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Utilisateurs Actifs',
                                  '${stats['activeUsers']}',
                                  Colors.teal,
                                  Icons.check_circle, // Icône pour utilisateurs actifs
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Utilisateurs Bloqués',
                                  '${stats['blockedUsers']}',
                                  Colors.red,
                                  Icons.block, // Icône pour utilisateurs bloqués
                                ),
                              ),
                            ],
                          )

                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

// Label pour la liste des utilisateurs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Liste des Utilisateurs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
// Partie qui affiche les utilisateurs avec un scroll si nécessaire
                  Expanded(
                    child: SingleChildScrollView( // Ajout de SingleChildScrollView pour rendre la liste scrollable
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('Utilisateurs').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final users = snapshot.data!.docs;

                          return Column( // Utilisation de Column pour permettre un scroll vertical de la liste
                            children: [
                              // Construction de la liste d'utilisateurs
                              for (var user in users)
                                Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.teal,
                                      child: Text(
                                        user['nom'][0],
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${user['nom']} ${user['prenom']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['email'] ?? 'Non spécifié',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: user['bloquer'] == true
                                        ? const Icon(Icons.block, color: Colors.red)
                                        : const Icon(Icons.check_circle, color: Colors.green),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}