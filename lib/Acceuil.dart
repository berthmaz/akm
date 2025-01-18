import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gestionammortissemet/GestionCompte.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:gestionammortissemet/Scanneur.dart';
import 'AjouterImmobilisation.dart';
import 'GestionUtilisateur.dart';

class AcceuilPage extends StatefulWidget {
  AcceuilPage({Key? key}) : super(key: key);

  bool administrateur = false;
  bool superadministrateur = false;
  User? currentUser;

  @override
  State<AcceuilPage> createState() => _AcceuilPageState();
}

class _AcceuilPageState extends State<AcceuilPage> {
  int _selectedIndex = 0;
  bool _isLoading = true; // Indicateur de chargement
  List<Widget> _pages = [];
  List<Map<String, dynamic>> _menuItems = [];

  String nom = "";
  String postnom = "";
  String prenom = "";
  String email = "";
  String contact = "";
  String photoUrl = "";

  @override
  void initState() {
    super.initState();
    _setupMenuAndPages(); // Configure les pages et menus
    _fetchUserInfo(); // Récupère les données utilisateur
  }

  Future<void> _fetchUserInfo() async {
    try {
      // Récupère l'utilisateur actuellement connecté depuis FirebaseAuth
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Requête Firestore pour trouver l'utilisateur avec userId égal à currentUser.uid
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('Utilisateurs')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        if (userQuery.docs.isNotEmpty) {
          // Récupère le premier document correspondant
          DocumentSnapshot userDoc = userQuery.docs.first;

          // Met à jour l'état avec les informations récupérées
          setState(() {
            nom = userDoc['nom'] ?? 'Nom indisponible';
            prenom = userDoc['prenom'] ?? 'Prénom indisponible';
            email = userDoc['email'] ?? 'Email indisponible';
            contact = userDoc['contact'] ?? 'Contact indisponible';
            photoUrl = userDoc['photoUrl'] ?? '';
            widget.administrateur = userDoc['administrateur'] ?? false;
            widget.superadministrateur = userDoc['superadministrateur'] ?? false;
          });
        } else {
          print("Aucun utilisateur trouvé avec userId = ${currentUser.uid}");
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération des informations utilisateur : $e");
    } finally {
      setState(() {
        _isLoading = false; // Fin du chargement
      });
    }
  }


  void _setupMenuAndPages() {
    _menuItems = [
      {
        'icon': Icons.add,
        'label': 'Ajouter amortissement',
        'page': GestionImmobilisationPage(),
      },

      {
        'icon': Icons.countertops,
        'label': 'Comptes OHADA',
        'page': GestionComptesPage(),
      },
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scanner QR Code',
        'page':QRScannerPage()
      },
      {
        'icon': Icons.manage_accounts,
        'label': 'Gérer utilisateurs',
        'page': GestionUtilisateursPage(utilisateur: {},)
      },
      {
        'icon': Icons.settings,
        'label': 'Paramètres',
        'page': const Center(child: Text('Page Paramètres')),
      },
      {
        'icon': Icons.logout,
        'label': 'Déconnexion',
        'page': const Center(child: Text('Page Déconnexion')),
      },
    ];

    _pages = _menuItems.map((item) => item['page'] as Widget).toList();
  }

  Widget _menuButton(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          leading: Icon(
            icon,
            color: _selectedIndex == index ? Colors.orange : Colors.white70,
            size: 30,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index ? Colors.orange : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5DADE2), // Couleur bleue du logo
        title: const Text(
          'AKM-AUDIT & CONTROLE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$nom $prenom',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                   email,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                backgroundColor: Colors.white,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 18, color: Colors.blueGrey)
                    : null,
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(200, 80, 10, 0),
                    items: [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          children: [
                            const Text(
                              'Paramètres',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: Colors.blueGrey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.account_circle, color: Colors.blueGrey),
                                title: Text(
                                  '$nom $prenom',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text('Nom & Prénom'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: Colors.blueGrey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.email, color: Colors.orange),
                                title: Text(
                                  email,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                subtitle: const Text('Email'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: Colors.blueGrey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.phone, color: Colors.orange),
                                title: Text(
                                  contact,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                subtitle: const Text('Contact'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () {
                                // Afficher la boîte de dialogue de déconnexion
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.warning, // Type de dialogue (avertissement)
                                  animType: AnimType.bottomSlide, // Animation
                                  title: 'Déconnexion',
                                  width: 600,
                                  desc: 'Êtes-vous sûr de vouloir vous déconnecter ?',
                                  btnCancelOnPress: () {
                                    print("Déconnexion annulée");
                                  },
                                  btnOkOnPress: () async {
                                    print("Déconnexion confirmée");
                                    try {
                                      await FirebaseAuth.instance.signOut(); // Déconnecter l'utilisateur
                                      print("Utilisateur déconnecté");
                                      // Rediriger vers l'écran de connexion ou une autre page
                                      Navigator.of(context).pushReplacementNamed('/login'); // Remplacez par votre route de connexion
                                    } catch (e) {
                                      print("Erreur lors de la déconnexion: $e");
                                    }
                                  },
                                  btnCancelText: 'Non',
                                  btnOkText: 'Oui',
                                ).show();
                              },
                              child: const Text(
                                'Se Déconnecter',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF2C3E50),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    UserAccountHeader(
                      nom,
                      postnom,
                      prenom,
                      email,
                      contact,
                      photoUrl,
                    ),
                    const Divider(color: Colors.white54),
                    for (int i = 0; i < _menuItems.length; i++)
                      _menuButton(
                          _menuItems[i]['icon'], _menuItems[i]['label'], i),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Afficher le contenu si les pages sont disponibles
                _pages.isNotEmpty
                    ? _pages[_selectedIndex]
                    : const Center(child: Text('Aucune page à afficher.')),

                // Afficher le spinner si _isLoading est true
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5), // Fond semi-transparent
                    child: const Center(
                      child: SpinKitCircle(
                        color: Colors.orange, // Spinner orange
                        size: 70.0, // Taille du spinner
                      ),
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }

}


class UserAccountHeader extends StatelessWidget {
  final String nom;
  final String postnom;
  final String prenom;
  final String email;
  final String contact;
  final String photoUrl;

  const UserAccountHeader(
      this.nom,
      this.postnom,
      this.prenom,
      this.email,
      this.contact,
      this.photoUrl,
      );
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          const Icon(
            Icons.menu,
            size: 30,
            color: Colors.white,
          ),
          const SizedBox(width: 15),
          const Text(
            'Menu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
