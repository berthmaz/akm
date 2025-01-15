import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DashBoardUser.dart';

class GestionUtilisateursPage extends StatefulWidget {
  const GestionUtilisateursPage({super.key, required Map<String, dynamic> utilisateur});

  @override
  _GestionUtilisateursPageState createState() =>
      _GestionUtilisateursPageState();
}

class _GestionUtilisateursPageState extends State<GestionUtilisateursPage> {
  TextEditingController _searchController = TextEditingController();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _postnomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();

  // Variables pour stocker les sélections des dropdowns
  String _selectedSexe = 'Femme';
  String _selectedFonction = 'Auditeur';
  String _selectedService = 'Direction Générale';
  String _selectedEntreprise = 'SNCC';
  String userId = '';


  List<Map<String, dynamic>> utilisateurs = []; // Declare as List<Map<String, dynamic>> instead of List<String>



  bool _isPasswordHidden = true;
  @override
  void initState() {
    super.initState();
    fetchUsers();  // Appeler la fonction pour récupérer les utilisateurs au démarrage
  }
  Future<void> fetchUsers() async {
    try {
      // Récupérer les utilisateurs depuis la collection 'Utilisateurs'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Utilisateurs').get();

      // Extraire les données de chaque document
      List<Map<String, dynamic>> usersList = querySnapshot.docs.map((doc) {
        return {
          'userId': doc.id,  // Keep doc.id as userId
          'nom': doc['nom'] ?? '',
          'prenom': doc['prenom'] ?? '',
          'contact': doc['contact'] ?? '',
          'email': doc['email'] ?? '',
          'motDePasse': doc['motDePasse'] ?? '',
        };
      }).toList();

      // Mettre à jour l'état avec la liste des utilisateurs
      setState(() {
        utilisateurs = usersList;  // Update with map of users, not just String
      });
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Impossible de récupérer les utilisateurs.',
        btnOkOnPress: () {},
      ).show();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Module : Gestion des Utilisateurs',
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
        iconTheme: IconThemeData(color: Colors.blueGrey), // Icônes en blueGrey également
        actions: [
          // Ajout du bouton "Tableau de bord" avec son icône
          IconButton(
            icon: const Icon(
              Icons.dashboard, // Icône tableau de bord
              color: Colors.blueGrey, // Icône en blueGrey
            ),
            onPressed: () {
              // Navigation vers la page DashBoardUser
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashBoardUser()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Frame 1: Informations sur l'utilisateur
              _buildUserInfoForm(),
              const SizedBox(height: 20),
              // Frame 2: Boutons Ajouter, Modifier, Supprimer
              _buildActionButtons(context),
              const SizedBox(height: 20),
              // Liste des utilisateurs dans un tableau moderne
              userListWidget(),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _deleteUser(BuildContext context, String userId) async {
    // Affichage de la boîte de dialogue de confirmation avec AwesomeDialog
    bool? confirmation = await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'Confirmer la suppression',
      desc: 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
      btnCancelOnPress: () {
        Navigator.of(context).pop(false); // L'utilisateur a choisi "Non"
      },
      btnOkOnPress: () {
        Navigator.of(context).pop(true); // L'utilisateur a choisi "Oui"
      },
      btnCancelText: 'Non',
      btnOkText: 'Oui',
      width: 600,  // Réduire la largeur du dialogue
      btnOkColor: Colors.orange,  // Optionnel: changer la couleur du bouton Ok
      btnCancelColor: Colors.red,  // Optionnel: changer la couleur du bouton Cancel
    ).show();

    // Si l'utilisateur a confirmé la suppression
    if (confirmation == true) {
      try {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore.collection('Utilisateurs').doc(userId).delete();

        // Afficher un message de succès avec AwesomeDialog
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.rightSlide,
          title: 'Succès',
          desc: 'Utilisateur supprimé avec succès !',
          btnOkOnPress: () {},
          width: 600,  // Réduire la largeur du dialogue
          dialogBackgroundColor: Colors.white,
        ).show();
      } catch (e) {
        print("Erreur lors de la suppression de l'utilisateur: $e");

        // Afficher un message d'erreur avec AwesomeDialog
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Erreur',
          desc: 'Erreur lors de la suppression de l\'utilisateur : $e',
          btnOkOnPress: () {},
          width: 600,  // Réduire la largeur du dialogue
          dialogBackgroundColor: Colors.white,
        ).show();
      }
    }
  }
  Future<void> _bloquerUser(BuildContext context, String userId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot userSnapshot = await firestore.collection('Utilisateurs').doc(userId).get();

      if (userSnapshot.exists) {
        var user = userSnapshot.data() as Map<String, dynamic>;

        // Vérification si l'utilisateur est déjà bloqué
        if (user['bloquer'] == true) {
          // L'utilisateur est déjà bloqué
          AwesomeDialog(
            context: context,
            dialogType: DialogType.info,
            animType: AnimType.rightSlide,
            title: 'Utilisateur déjà bloqué',
            desc: 'Cet utilisateur est déjà bloqué.',
            btnOkOnPress: () {},
            width: 600,
            dialogBackgroundColor: Colors.white,
          ).show();
          return;  // Sortir de la fonction si l'utilisateur est déjà bloqué
        }

        // Affichage de la boîte de dialogue de confirmation avec AwesomeDialog
        bool? confirmation = await AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Confirmer le blocage',
          desc: 'Êtes-vous sûr de vouloir bloquer cet utilisateur ?',
          btnCancelOnPress: () {
            Navigator.of(context).pop(false); // L'utilisateur a choisi "Non"
          },
          btnOkOnPress: () {
            Navigator.of(context).pop(true); // L'utilisateur a choisi "Oui"
          },
          btnCancelText: 'Non',
          btnOkText: 'Oui',
          width: 600,
          btnOkColor: Colors.orange,
          btnCancelColor: Colors.red,
        ).show();

        // Si l'utilisateur a confirmé l'action
        if (confirmation == true) {
          await firestore.collection('Utilisateurs').doc(userId).set({
            'bloquer': true,
          });

          // Afficher un message de succès avec AwesomeDialog
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Succès',
            desc: 'Utilisateur bloqué avec succès !',
            btnOkOnPress: () {},
            width: 600,
            dialogBackgroundColor: Colors.white,
          ).show();
        }
      }
    } catch (e) {
      print("Erreur lors du blocage de l'utilisateur: $e");

      // Afficher un message d'erreur avec AwesomeDialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors du blocage de l\'utilisateur : $e',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    }
  }
  Future<void> _debloquerUser(BuildContext context, String userId) async {
    if (userId.isEmpty) {
      // Afficher un message d'erreur si userId est vide
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'L\'ID de l\'utilisateur est invalide.',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
      return; // Sortir de la fonction si l'ID est invalide
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot userSnapshot = await firestore.collection('Utilisateurs').doc(userId).get();

      if (userSnapshot.exists) {
        var user = userSnapshot.data() as Map<String, dynamic>;

        // Vérification si l'utilisateur est déjà débloqué
        if (user['bloquer'] == false) {
          // L'utilisateur est déjà débloqué
          AwesomeDialog(
            context: context,
            dialogType: DialogType.info,
            animType: AnimType.rightSlide,
            title: 'Utilisateur déjà débloqué',
            desc: 'Cet utilisateur est déjà débloqué.',
            btnOkOnPress: () {},
            width: 600,
            dialogBackgroundColor: Colors.white,
          ).show();
          return;  // Sortir de la fonction si l'utilisateur est déjà débloqué
        }

        // Affichage de la boîte de dialogue de confirmation avec AwesomeDialog
        bool? confirmation = await AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Confirmer le déblocage',
          desc: 'Êtes-vous sûr de vouloir débloquer cet utilisateur ?',
          btnCancelOnPress: () {
            Navigator.of(context).pop(false); // L'utilisateur a choisi "Non"
          },
          btnOkOnPress: () {
            Navigator.of(context).pop(true); // L'utilisateur a choisi "Oui"
          },
          btnCancelText: 'Non',
          btnOkText: 'Oui',
          width: 600,
          btnOkColor: Colors.green,
          btnCancelColor: Colors.red,
        ).show();

        // Si l'utilisateur a confirmé l'action
        if (confirmation == true) {
          await firestore.collection('Utilisateurs').doc(userId).set({
            'bloquer': false,
          });

          // Afficher un message de succès avec AwesomeDialog
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Succès',
            desc: 'Utilisateur débloqué avec succès !',
            btnOkOnPress: () {},
            width: 600,
            dialogBackgroundColor: Colors.white,
          ).show();
        }
      }
    } catch (e) {
      print("Erreur lors du déblocage de l'utilisateur: $e");

      // Afficher un message d'erreur avec AwesomeDialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors du déblocage de l\'utilisateur : $e',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    }
  }

  Widget userListWidget() {
    // Méthode pour rechercher des utilisateurs dans Firestore
    Stream<QuerySnapshot> _searchUser(String searchTerm) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      if (searchTerm.isEmpty) {
        return firestore.collection('Utilisateurs').snapshots();
      }

      return firestore
          .collection('Utilisateurs')
          .where('nom', isGreaterThanOrEqualTo: searchTerm)
          .where('nom', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .snapshots();
    }

    // Fonction pour supprimer un utilisateur
    Future<void> _deleteUser(String userId) async {
      try {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore.collection('Utilisateurs').doc(userId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilisateur supprimé avec succès.')),
        );
      } catch (e) {
        print("Erreur lors de la suppression : $e");
      }
    }

    // Fonction pour éditer un utilisateur
    void _editUser(Map<String, dynamic> userData) {
      _nomController.text = userData['nom'] ?? '';
      _prenomController.text = userData['prenom'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _contactController.text = userData['contact'] ?? '';
      _motDePasseController.text = userData['motDePasse'] ?? '';
      userId = userData['userId'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ de recherche
          TextField(
            controller: _searchController,
            onChanged: (searchTerm) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: Icon(Icons.search, color: Colors.teal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          SizedBox(height: 20),
          Card(
            elevation: 8,
            shadowColor: Colors.grey.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _searchUser(_searchController.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Aucun utilisateur trouvé"));
                }

                var utilisateurs = snapshot.data!.docs;

                // Ajout de la barre de défilement horizontale
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    // Largeur minimale pour forcer le débordement horizontal
                    width: 1200,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowHeight: 56,
                      dataRowHeight: 60,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('Nom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Prénom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      ],
                      rows: utilisateurs.map((user) {
                        var userData = user.data() as Map<String, dynamic>;

                        return DataRow(cells: [
                          DataCell(Text(userData['nom'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(userData['prenom'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(userData['contact'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(userData['email'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editUser(userData),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user.id),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );

              },
            ),
          ),
        ],
      ),
    );

  }
  // Frame 1: Informations sur l'utilisateur
  Widget _buildUserInfoForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            // Nom, Postnom, Prénom
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _nomController,
                    'Nom',
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _prenomController,
                    'Prénom',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 20),
            // Contact, Email, Mot de Passe
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _contactController,
                    'Contact',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildPasswordField(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Frame 2: Boutons Ajouter, Modifier, Supprimer
  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bordure arrondie pour l'effet moderne
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Espacement interne
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                // Appeler la fonction pour ajouter un utilisateur
                _addUserToFirestore(context); // Appelez la fonction lorsque le bouton est pressé
              },
              icon: const Icon(Icons.add, size: 24, color: Colors.white),
              label: const Text(
                'Ajouter',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                minimumSize: const Size(150, 50),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Appeler la fonction de mise à jour avec l'ID de l'utilisateur
                _updateUserInFirestore(context);

                // Modifier l'utilisateur
              },
              icon: const Icon(Icons.edit, size: 20, color: Colors.white),
              label: const Text('Modifier', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                minimumSize: const Size(150, 50),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Appeler la fonction de mise à jour avec l'ID de l'utilisateur
                _bloquerUser(context, userId );
                // Modifier l'utilisateur
              },
              icon: const Icon(Icons.lock, size: 20, color: Colors.white),
              label: const Text('Bloquer', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                minimumSize: const Size(150, 50),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Appeler la fonction de mise à jour avec l'ID de l'utilisateur
                _debloquerUser(context, userId);

                // Modifier l'utilisateur
              },
              icon: const Icon(Icons.lock_outline, size: 20, color: Colors.white),
              label: const Text('Débloquer', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                minimumSize: const Size(150, 50),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _deleteUser(context, userId);
                // Supprimer l'utilisateur
              },
              icon: const Icon(Icons.delete, size: 20, color: Colors.white),
              label: const Text('Supprimer', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                minimumSize: const Size(150, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _updateUserInFirestore(BuildContext context) async {
    // Récupérer les valeurs des champs
    final String email = _emailController.text.trim();
    final String contact = _contactController.text.trim();
    final String nom = _nomController.text.trim();
    final String prenom = _prenomController.text.trim();
    final String motDePasse = _motDePasseController.text.trim();
    // Vérifier que les champs essentiels ne sont pas vides
    if (email.isEmpty || contact.isEmpty || nom.isEmpty  || prenom.isEmpty || motDePasse.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'Attention',
        desc: 'Tous les champs doivent être remplis.',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
      return; // Arrêter si un champ est vide
    }

    // Construire les nouvelles données utilisateur
    final Map<String, dynamic> utilisateur = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'contact': contact,
      'motDePasse': motDePasse,

    };
    try {
      // Mettre à jour l'utilisateur dans Firestore
      await FirebaseFirestore.instance
          .collection('Utilisateurs')
          .doc(userId)  // Utiliser l'ID de l'utilisateur pour la mise à jour
          .update(utilisateur);

      // Afficher le message de succès
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Succès',
        desc: 'Utilisateur mis à jour avec succès !',
        btnOkOnPress: () {
          _clearFields(); // Réinitialiser les champs après succès
        },
        width: 600,
        dialogBackgroundColor: Colors.white,).show();
    } catch (e) {
      // Afficher le message d'erreur
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors de la mise à jour de l\'utilisateur : $e',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    }
  }

  void _addUserToFirestore(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String contact = _contactController.text.trim();
    final String nom = _nomController.text.trim();
    final String postnom = _postnomController.text.trim();
    final String prenom = _prenomController.text.trim();
    final String motDePasse = _motDePasseController.text.trim();


    // Vérifier que les champs essentiels ne sont pas vides
    if (email.isEmpty ||
        contact.isEmpty ||
        nom.isEmpty ||
        postnom.isEmpty ||
        prenom.isEmpty ||
        motDePasse.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'Attention',
        desc: 'Tous les champs doivent être remplis.',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
      return;
    }

    try {
      // Vérifier si l'email ou le contact existe déjà dans Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Utilisateurs')
          .where('email', isEqualTo: email)
          .get();

      final contactSnapshot = await FirebaseFirestore.instance
          .collection('Utilisateurs')
          .where('contact', isEqualTo: contact)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Attention',
          desc: 'L\'email est déjà utilisé par un autre utilisateur.',
          btnOkOnPress: () {},
          width: 600,
          dialogBackgroundColor: Colors.white,
        ).show();
        return;
      }

      if (contactSnapshot.docs.isNotEmpty) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Attention',
          desc: 'Le contact est déjà utilisé par un autre utilisateur.',
          btnOkOnPress: () {},
          width: 600,
          dialogBackgroundColor: Colors.white,
        ).show();
        return;
      }

      // Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: motDePasse);

      // Récupérer l'ID utilisateur généré par Firebase Auth
      String userId = userCredential.user?.uid ?? '';

      // Construire les données utilisateur pour Firestore
      final utilisateur = {
        'userId': userId,
        'nom': nom,
        'postnom': postnom,
        'prenom': prenom,
        'email': email,
        'contact': contact,
        'administrateur': false,
        'motDePasse': motDePasse,
        'adminPrincipal': false,
        'bloquer': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Ajouter l'utilisateur dans Firestore
      await FirebaseFirestore.instance.collection('Utilisateurs').doc(userId).set(utilisateur);

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Succès',
        desc: 'Utilisateur créé et ajouté avec succès !',
        btnOkOnPress: () {
          _clearFields(); // Réinitialiser les champs après succès
        },
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    } catch (e) {
      // Afficher le message d'erreur
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors de la création de l\'utilisateur : $e',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    }
  }

// Fonction pour réinitialiser les champs après ajout
  void _clearFields() {
    _nomController.clear();
    _postnomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _contactController.clear();
    _motDePasseController.clear();
  }
  // Fonction pour construire un champ de texte
  Widget _buildTextField(TextEditingController controller, String label,
      IconData prefixIcon,
      {bool obscureText = false,
        TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(prefixIcon, color: Colors.black),
      ),
    );
  }

  // Fonction pour construire un champ de mot de passe
  Widget _buildPasswordField() {
    return TextField(
      controller: _motDePasseController,
      obscureText: _isPasswordHidden,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Mot de Passe',
        labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: const Icon(Icons.lock, color: Colors.black),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
            color: Colors.green,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
    );
  }

  // Fonction pour basculer la visibilité du mot de passe
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

// Méthode pour construire un DropdownField
  Widget _buildDropdownField(
      String label,
      List<String> items,
      String selectedItem,
      ValueChanged<String?> onChanged,
      IconData icon,
      ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: selectedItem,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(icon, color: Colors.black), // Icône pour chaque item
              const SizedBox(width: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
      isExpanded: true,
      isDense: true,
    );
  }
}
