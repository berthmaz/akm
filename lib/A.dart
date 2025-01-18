import 'dart:math';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'DashBoardImmobilisation.dart';
import 'DashBoardUser.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GestionImmobilisationPage extends StatefulWidget {
  const GestionImmobilisationPage({super.key});

  @override
  _GestionImmobilisationPageState createState() =>
      _GestionImmobilisationPageState();
}

class _GestionImmobilisationPageState extends State<GestionImmobilisationPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _compteGeneralController = TextEditingController();
  final TextEditingController _familleController = TextEditingController();
  final TextEditingController _nomenclatureController = TextEditingController();
  final TextEditingController _emplacementController = TextEditingController();
  final TextEditingController _fournisseurController = TextEditingController();
  final TextEditingController _valeurOrigineController = TextEditingController();
  final TextEditingController _factureController = TextEditingController();
  final TextEditingController _affectataireController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();
  final TextEditingController _tauxController = TextEditingController();
  final TextEditingController _ammorAnterieurController = TextEditingController();
  final TextEditingController _ammorCumulController = TextEditingController();
  final TextEditingController _ammorExerciceController = TextEditingController();
  final TextEditingController _valeurnetController = TextEditingController();
  final TextEditingController _imobIdController = TextEditingController();
  final TextEditingController _dateMiseServiceController = TextEditingController();
  final TextEditingController _valeurResiduelleController = TextEditingController();
  final TextEditingController _montantAmortissableController = TextEditingController();
  final TextEditingController _tauxAmortissementController = TextEditingController();
  final TextEditingController _amortissementsAnterieursController = TextEditingController();
  final TextEditingController _annuitesAmortissementController = TextEditingController();
  final TextEditingController _cumulAmortissementsController = TextEditingController();
  final TextEditingController _vncController = TextEditingController();




  bool isLoading = false;
  String docId= '';
  String _selectedStructure = "Intégrale";
  String _selectedMethode = "Linéaire";
  String? _photoUrl;
  String _selectedEtat = "Neuf";
  String _selectedCompteGeneral = ''; // Compte sélectionné
  List<Map<String, String>> comptesList = []; // Liste des comptes récupérés
  final List<String> _structureList = ["Intégrale", "Composante"];
  final List<String> _methodeList = ["Linéaire", "Dégressif"];
  final List<String> _etatList = ["Neuf", "Bon", "Vétuste", "Panne"];

  List<Map<String, dynamic>> utilisateurs = []; // Declare as List<Map<String, dynamic>> instead of List<String>
  Uint8List? _selectedImage; // Compatible avec Flutter Web
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchImmobilisations();
    _generateImobId();

    // Ajouter des écouteurs pour les champs qui influencent les calculs
    _valeurOrigineController.addListener(_updateCalculatedFields);
    _valeurResiduelleController.addListener(_updateCalculatedFields);
    _dureeController.addListener(_updateCalculatedFields);
    _dateMiseServiceController.addListener(_updateCalculatedFields);
    _ammorAnterieurController.addListener(_updateCalculatedFields);

    // Appeler les calculs au chargement de la page
    _updateCalculatedFields();
  }

  @override
  void dispose() {
    // Nettoyer les écouteurs pour éviter les fuites de mémoire
    _valeurOrigineController.removeListener(_updateCalculatedFields);
    _valeurResiduelleController.removeListener(_updateCalculatedFields);
    _dureeController.removeListener(_updateCalculatedFields);
    _dateMiseServiceController.removeListener(_updateCalculatedFields);
    _ammorAnterieurController.removeListener(_updateCalculatedFields);
    super.dispose();
  }
  void _updateCalculatedFields() {
    // Appeler toutes les fonctions de calcul
    _calculateMontantAmortissable();
    _calculateTauxAmortissement();
    _calculateAnnuitesAmortissement();
    _calculateCumulAmortissements();
    _calculateVNC();
  }

  void _calculateMontantAmortissable() {
    double valeurEntree = double.tryParse(_valeurOrigineController.text) ?? 0;
    double valeurResiduelle = double.tryParse(_valeurResiduelleController.text) ?? 0;
    double montantAmortissable = valeurEntree - valeurResiduelle;
    setState(() {
      _montantAmortissableController.text = montantAmortissable.toStringAsFixed(2);
    });
  }

  void _calculateTauxAmortissement() {
    int dureeVie = int.tryParse(_dureeController.text) ?? 1;
    double tauxAmortissement = 100 / dureeVie;
    setState(() {
      _tauxAmortissementController.text = tauxAmortissement.toStringAsFixed(2);
    });
  }

  void _calculateAnnuitesAmortissement() {
    double valeurOrigine = double.tryParse(_valeurOrigineController.text) ?? 0;
    double tauxAmortissement = double.tryParse(_tauxAmortissementController.text) ?? 0;
    DateTime dateMiseService = DateFormat('dd/MM/yyyy').parse(_dateMiseServiceController.text);
    DateTime finAnnee = DateTime(DateTime.now().year, 12, 31);
    int jours = finAnnee.difference(dateMiseService).inDays;
    double annuitesAmortissement = valeurOrigine * (tauxAmortissement / 100) * (jours / 360);
    setState(() {
      _annuitesAmortissementController.text = annuitesAmortissement.toStringAsFixed(2);
    });
  }

  void _calculateCumulAmortissements() {
    double amortissementsAnterieurs = double.tryParse(_amortissementsAnterieursController.text) ?? 0;
    double annuitesAmortissement = double.tryParse(_annuitesAmortissementController.text) ?? 0;
    double cumulAmortissements = amortissementsAnterieurs + annuitesAmortissement;
    setState(() {
      _cumulAmortissementsController.text = cumulAmortissements.toStringAsFixed(2);
    });
  }

  void _calculateVNC() {
    double valeurOrigine = double.tryParse(_valeurOrigineController.text) ?? 0;
    double cumulAmortissements = double.tryParse(_cumulAmortissementsController.text) ?? 0;
    double vnc = valeurOrigine - cumulAmortissements;
    setState(() {
      _vncController.text = vnc.toStringAsFixed(2);
    });
  }


  Future<void> fetchImmobilisations() async {
    try {
      // Récupérer les immobilisations depuis la collection 'Immobilisations'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Immobilisations').get();

      // Extraire les données de chaque document
      List<Map<String, dynamic>> immobilisationsList = querySnapshot.docs.map((doc) {
        return {
          'docId': doc.id, // Inclure le docId
          'ImobId': doc['ImobId'] ?? '',
          'compteGeneral': doc['compteGeneral'] ?? '',
          'famille': doc['famille'] ?? '',
          'nomenclature': doc['nomenclature'] ?? '',
          'emplacement': doc['emplacement'] ?? '',
          'fournisseur': doc['fournisseur'] ?? '',
          'valeurOrigine': doc['valeurOrigine'] ?? '',
          'facture': doc['facture'] ?? '',
          'affectataire': doc['affectataire'] ?? '',
          'date': doc['date'] ?? '',
          'duree': doc['duree'] ?? '',
          'taux': doc['taux'] ?? '',
          'ammorAnterieur': doc['ammorAnterieur'] ?? '',
          'photoImob': doc['photoImob'] ?? '',
          'ammorCumul': doc['ammorCumul'] ?? '',
          'ammorExercice': doc['ammorExercice'] ?? '',
          'valeurNet': doc['valeurNet'] ?? '',
          'dateCreation': doc['dateCreation'] ?? '',
          'derniereModification': doc['derniereModification'] ?? '',
        };
      }).toList();

      // Mettre à jour l'état avec la liste des immobilisations
      setState(() {
        utilisateurs = immobilisationsList; // Mise à jour avec la liste des immobilisations
      });

    } catch (e) {
      print('Erreur lors de la récupération des immobilisations: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Impossible de récupérer les immobilisations.',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<List<Map<String, String>>> fetchComptes() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Comptes').get();

      // Convertir les données en Map<String, String>
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'compteGeneral': (data['compteGeneral'] ?? '').toString(),
          'intituleCompte': (data['intituleCompte'] ?? '').toString(),
        };
      }).toList();
    } catch (e) {
      print("Erreur lors de la récupération des comptes: $e");
      return [];
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          // Lecture en tant que Uint8List pour Flutter Web
          final Uint8List imageData = await pickedFile.readAsBytes();
          setState(() {
            _selectedImage = imageData; // Stockage de l'image sélectionnée
          });
        } else {
          // Si nécessaire pour mobile
          final File file = File(pickedFile.path);
          print("Image sélectionnée (mobile) : ${file.path}");
        }
      } else {
        print("Aucune image sélectionnée.");
      }
    } catch (e) {
      print("Erreur lors de la sélection de l'image : $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Module : Gérer immobilisation',
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
                MaterialPageRoute(builder: (context) => ImmobilisationDashboard()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
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
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Fond semi-transparent
              child: const Center(
                child: SpinKitCircle(
                  color: Colors.orange, // Spinner orange
                  size: 70.0,
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget userListWidget() {
    // Méthode pour rechercher des utilisateurs dans Firestore
    // Méthode pour rechercher des utilisateurs dans Firestore
    Stream<List<QueryDocumentSnapshot>> _searchUser(String searchTerm) async* {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      if (searchTerm.isEmpty) {
        yield* firestore.collection('Immobilisations').snapshots().map((snapshot) => snapshot.docs);
      } else {
        // Recherches pour chaque champ
        var familleQuery = firestore
            .collection('Immobilisations')
            .where('famille', isGreaterThanOrEqualTo: searchTerm)
            .where('famille', isLessThanOrEqualTo: searchTerm + '\uf8ff')
            .snapshots();

        var factureQuery = firestore
            .collection('Immobilisations')
            .where('facture', isGreaterThanOrEqualTo: searchTerm)
            .where('facture', isLessThanOrEqualTo: searchTerm + '\uf8ff')
            .snapshots();

        var nomenclatureQuery = firestore
            .collection('Immobilisations')
            .where('nomenclature', isGreaterThanOrEqualTo: searchTerm)
            .where('nomenclature', isLessThanOrEqualTo: searchTerm + '\uf8ff')
            .snapshots();

        var compteGeneralQuery = firestore
            .collection('Immobilisations')
            .where('compteGeneral', isGreaterThanOrEqualTo: searchTerm)
            .where('compteGeneral', isLessThanOrEqualTo: searchTerm + '\uf8ff')
            .snapshots();

        // Combine les résultats des requêtes
        await for (var familleSnapshot in familleQuery) {
          var factureSnapshot = await factureQuery.first;
          var nomenclatureSnapshot = await nomenclatureQuery.first;
          var compteGeneralSnapshot = await compteGeneralQuery.first;

          // Combine les documents de toutes les requêtes
          var combinedDocs = [
            ...familleSnapshot.docs,
            ...factureSnapshot.docs,
            ...nomenclatureSnapshot.docs,
            ...compteGeneralSnapshot.docs,
          ];

          // Filtre les doublons
          yield combinedDocs.toSet().toList();
        }
      }
    }



    void _editUser(Map<String, dynamic> immobilisationData) {
      // Remplir les champs du formulaire avec les données de l'immobilisation
      _compteGeneralController.text = immobilisationData['compteGeneral'] ?? '';
      _familleController.text = immobilisationData['famille'] ?? '';
      _nomenclatureController.text = immobilisationData['nomenclature'] ?? '';
      _emplacementController.text = immobilisationData['emplacement'] ?? '';
      _fournisseurController.text = immobilisationData['fournisseur'] ?? '';
      _valeurOrigineController.text = immobilisationData['valeurOrigine'] ?? '';
      _factureController.text = immobilisationData['facture'] ?? '';
      _affectataireController.text = immobilisationData['affectataire'] ?? '';
      _dateController.text = immobilisationData['date'] ?? '';
      _dureeController.text = immobilisationData['duree'] ?? '';
      _tauxController.text = immobilisationData['taux'] ?? '';
      _ammorAnterieurController.text = immobilisationData['ammorAnterieur'] ?? '';
      _ammorCumulController.text = immobilisationData['ammorCumul'] ?? '';
      _ammorExerciceController.text = immobilisationData['ammorExercice'] ?? '';
      _valeurnetController.text = immobilisationData['valeurNet'] ?? '';
      _imobIdController.text = immobilisationData['ImobId'] ?? '';

      // Récupérer le docId
      if (immobilisationData['docId'] != null) {
        docId = immobilisationData['docId']!;
        print("docId correctement récupéré : $docId");
      } else {
        throw Exception("docId est null dans immobilisationData.");
      }

      // Gestion de l'image
      final String? photoUrl = immobilisationData['photoImob'];
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          // Récupérer l'image depuis l'URL et l'afficher
          setState(() {
            _selectedImage = null; // Réinitialise l'image sélectionnée
            _photoUrl = photoUrl; // URL de la photo
          });
        } catch (e) {
          print("Erreur lors du chargement de l'image : $e");
        }
      } else {
        // Pas d'image associée
        setState(() {
          _photoUrl = null;
        });
      }
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
              hintText: "Rechercher l'immobilisation...",
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
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _searchUser(_searchController.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Aucune immobilisation trouvée"));
                }
                var immobilisations = snapshot.data!;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowHeight: 56,
                      dataRowHeight: 60,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('N° Compte Général', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Famille', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Nomenclature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Emplacement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Fournisseur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Valeur d\'Origine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('N° Facture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Affectataire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Date Acquisition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Durée Annuelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Taux (%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Amortissement Antérieur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Amortissement Cumul', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Amortissement Exercice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Valeur Nette Comptable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      ],
                      rows: immobilisations.map((immobilisation) {
                        var immobilisationData = immobilisation.data() as Map<String, dynamic>;

                        return DataRow(cells: [
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editUser(immobilisationData),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(immobilisationData['compteGeneral'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['famille'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['nomenclature'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['emplacement'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['fournisseur'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['valeurOrigine'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['facture'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['affectataire'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['date'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['duree'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['taux'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['ammorAnterieur'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['ammorCumul'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['ammorExercice'] ?? '', style: TextStyle(fontSize: 14))),
                          DataCell(Text(immobilisationData['valeurNet'] ?? '', style: TextStyle(fontSize: 14))),
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
            GestureDetector(
              onTap: _pickImage, // Permet de sélectionner une nouvelle image
              child: Container(
                width: 100, // Largeur du carré
                height: 100, // Hauteur du carré
                decoration: BoxDecoration(
                  color: Colors.indigo, // Couleur de fond
                  borderRadius: BorderRadius.circular(8), // Coins arrondis
                  image: _selectedImage != null
                      ? DecorationImage(
                    image: MemoryImage(_selectedImage!), // Affiche l'image sélectionnée
                    fit: BoxFit.cover, // Adapte l'image à la taille du carré
                  )
                      : _photoUrl != null
                      ? DecorationImage(
                    image: NetworkImage(_photoUrl!), // Affiche l'image depuis l'URL
                    fit: BoxFit.cover,
                  )
                      : null, // Aucun décorateur si pas d'image
                ),
                child: _selectedImage == null && _photoUrl == null
                    ? const Icon(
                  Icons.add_a_photo,
                  size: 50,
                  color: Colors.white,
                )
                    : null, // Si une image est disponible, aucun icône n'est affiché
              ),
            ),

            const SizedBox(height: 20),
            // Ligne 1 : N° Compte Général, Famille, Nomenclature
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _imobIdController,
                    'ID',
                    Icons.perm_identity,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: fetchComptes(), // Récupération des comptes depuis Firestore
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("Aucun compte trouvé", style: TextStyle(fontSize: 14)),
                        );
                      }

                      var comptes = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'N° Compte Général',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _compteGeneralController.text.isEmpty
                            ? null
                            : _compteGeneralController.text,
                        onChanged: (String? newValue) {
                          setState(() {
                            _compteGeneralController.text = newValue!;
                          });
                        },
                        items: comptes.map((compte) {
                          return DropdownMenuItem<String>(
                            value: compte['compteGeneral'],
                            child: Text(
                              "${compte['compteGeneral']} - ${compte['intituleCompte']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _nomenclatureController,
                    'Nomenclature',
                    Icons.list_alt,
                    readOnly: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 2 : Structure, Emplacement, Affectataire
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _familleController,
                    'Famille',
                    Icons.category,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField(
                    'Structure',
                    _structureList,
                    _selectedStructure,
                        (String? newValue) {
                      setState(() {
                        _selectedStructure = newValue!;
                      });
                    },
                    Icons.layers,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _emplacementController,
                    'Emplacement',
                    Icons.location_on,
                    readOnly: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 3 : Date d'acquisition, Fournisseur, N° Facture
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _affectataireController,
                    'Affectataire',
                    Icons.person,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _fournisseurController,
                    'Fournisseur',
                    Icons.store,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _factureController,
                    'N° Facture',
                    Icons.receipt,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 4 : Valeur d'origine, Méthode d'amortissement
            Row(
              children: [
                Expanded(
                  child: buildDatePicker(
                    _dateController,
                    "Date d'acquisition",
                    Icons.date_range,
                    context,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _valeurOrigineController,
                    "Valeur d'origine",
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField(
                    "Méthode d'amortissement",
                    _methodeList,
                    _selectedMethode,
                        (String? newValue) {
                      setState(() {
                        _selectedMethode = newValue!;
                      });
                    },
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 5 : Durée annuelle, Taux
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _dureeController,
                    'Durée annuelle',
                    Icons.timer,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _tauxController,
                    'Taux (%)',
                    Icons.percent,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 6 : Amortissement antérieur, Amortissement exercice
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _ammorAnterieurController,
                    'Amortissement antérieur',
                    Icons.history,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _ammorExerciceController,
                    'Amortissement exercice',
                    Icons.timeline,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 7 : Amortissement cumul, Valeur nette comptable, État
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _ammorCumulController,
                    'Amortissement cumul',
                    Icons.bar_chart,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _valeurnetController,
                    'Valeur nette comptable',
                    Icons.account_balance,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField(
                    'État',
                    _etatList,
                    _selectedEtat,
                        (String? newValue) {
                      setState(() {
                        _selectedEtat = newValue!;
                      });
                    },
                    Icons.info_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 8 : Date de mise en service, Valeur résiduelle
            Row(
              children: [
                Expanded(
                  child: buildDatePicker(
                    _dateMiseServiceController,
                    "Date de mise en service",
                    Icons.date_range,
                    context,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _valeurResiduelleController,
                    'Valeur résiduelle',
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 9 : Montant amortissable, Taux d'amortissement
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _montantAmortissableController,
                    'Montant amortissable',
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _tauxAmortissementController,
                    'Taux d\'amortissement (%)',
                    Icons.percent,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ligne 10 : Annuités d'amortissement, Cumul des amortissements
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _annuitesAmortissementController,
                    'Annuités d\'amortissement',
                    Icons.timeline,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _cumulAmortissementsController,
                    'Cumul des amortissements',
                    Icons.bar_chart,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bouton pour recalculer les valeurs
            ElevatedButton(
              onPressed: () {
                _calculateMontantAmortissable();
                _calculateTauxAmortissement();
                _calculateAnnuitesAmortissement();
                _calculateCumulAmortissements();
                _calculateVNC();
              },
              child: Text('Recalculer les valeurs'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> generateAndDownloadImmobilisationCard({
    required BuildContext context,
    required Map<String, dynamic> immobilisationData,
    required String logoPath,
    required String ImobId,
  }) async {
    setState(() {
      isLoading = true; // Active la barre de progression
    });

    try {
      // Vérification si docId est présent
      if (!immobilisationData.containsKey('docId') || immobilisationData['docId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur : docId introuvable dans les données d'immobilisation."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false; // Désactive la barre de progression
        });
        return;
      }

      // Récupération de docId
      final String docId = immobilisationData['docId'] ?? "ID inconnu";

      // Charger le logo en tant qu'Uint8List
      final ByteData logoData = await rootBundle.load(logoPath);
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      // Génération des données QR Code
      final qrCodeData = docId;

      // Création du document PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Center(
              child: pw.Container(
                width: PdfPageFormat.a4.width * 0.8,
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue, width: 3),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // En-tête avec logo, titre et QR code
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(
                          pw.MemoryImage(logoBytes),
                          width: 80,
                          height: 80,
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'AKM-AUDIT & CONTROLE',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal,
                              ),
                            ),
                            pw.Text(
                              'Carte Immobilisation',
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.Text(
                              'N° 000-000-${ImobId}',
                              style: pw.TextStyle(
                                fontSize: 14,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        pw.BarcodeWidget(
                          data: qrCodeData,
                          barcode: pw.Barcode.qrCode(),
                          width: 80,
                          height: 80,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Certification
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue100,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        "Cette carte certifie l'immobilisation des biens\npar AKM-AUDIT & CONTROLE.",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Sauvegarde ou téléchargement
      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = 'Carte_Immobilisation.pdf';
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/Carte_Immobilisation.pdf');
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La carte d\'immobilisation a été enregistrée : ${file.path}'),
          ),
        );
      }
    } catch (e, stacktrace) {
      print("Erreur : $e\n$stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la génération du PDF : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Désactive la barre de progression
      });
    }
  }

  Widget buildDatePicker(
      TextEditingController controller,
      String label,
      IconData prefixIcon,
      BuildContext context, // Ajouter le context pour le showDatePicker
      ) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      readOnly: true, // Rendre le TextField en lecture seule pour ouvrir le sélecteur de date
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.teal, width: 2.0), // Couleur de la bordure
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
          borderRadius: BorderRadius.circular(15.0),
        ),
        filled: true,
        fillColor: Colors.teal.shade50, // Couleur de fond claire
        prefixIcon: Icon(prefixIcon, color: Colors.teal),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
      ),
      onTap: () async {
        // Ouvrir le sélecteur de date lors de l'appui sur le TextField
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2101),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.teal, // Couleur de la barre de sélection
                hintColor: Colors.teal,
                buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          // Formater la date choisie et l'afficher dans le TextField
          controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        }
      },
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
                _addImmobilisationToFirestore(context); // Appelez la fonction lorsque le bouton est pressé
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
                _updateImmobilisationInFirestore(context,);
              },
              icon: const Icon(Icons.edit, size: 20, color: Colors.white),
              label: const Text(
                'Modifier',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
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
                _deleteImmobilisation(context);
              },
              icon: const Icon(Icons.delete, size: 20, color: Colors.white),
              label: const Text(
                'Supprimer',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
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
              onPressed: () async {
                // Vérifier que le champ `docId` est non null avant de générer la carte
                if (docId.isEmpty) {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.warning,
                    animType: AnimType.rightSlide,
                    title: 'Attention',
                    desc: 'Le champ docId est manquant. Veuillez vérifier les données.',
                    btnOkOnPress: () {},
                  ).show();
                  return;
                }

                // Construire les données avec `docId` inclus
                final Map<String, dynamic> immobilisationData = {
                  'docId': docId.trim(), // Ajout explicite de `docId`
                };
                // Appeler la fonction pour générer et télécharger le PDF
                await generateAndDownloadImmobilisationCard(
                  context: context,
                  immobilisationData: immobilisationData,
                  ImobId: _imobIdController.text.trim(),
                  logoPath: 'assets/akm.png', // Chemin vers le logo
                );
              },
              icon: const Icon(Icons.download, size: 24, color: Colors.white),
              label: const Text(
                'Générer Carte',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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


  void _addImmobilisationToFirestore(BuildContext context) async {
    setState(() {
      isLoading = true; // Active le loader
    });

    final String imobId = _imobIdController.text.trim();
    final String compteGeneral = _compteGeneralController.text.trim();
    final String famille = _familleController.text.trim();
    final String nomenclature = _nomenclatureController.text.trim();
    final String emplacement = _emplacementController.text.trim();
    final String fournisseur = _fournisseurController.text.trim();
    final String valeurOrigine = _valeurOrigineController.text.trim();
    final String facture = _factureController.text.trim();
    final String affectataire = _affectataireController.text.trim();
    final String date = _dateController.text.trim();
    final String duree = _dureeController.text.trim();
    final String taux = _tauxController.text.trim();
    final String ammorAnterieur = _ammorAnterieurController.text.trim();
    final String ammorCumul = _ammorCumulController.text.trim();
    final String ammorExercice = _ammorExerciceController.text.trim();
    final String valeurNet = _valeurnetController.text.trim();

    // Formater la date actuelle
    final String formattedDate =
    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    if (imobId.isEmpty ||
        compteGeneral.isEmpty ||
        famille.isEmpty ||
        nomenclature.isEmpty ||
        emplacement.isEmpty ||
        fournisseur.isEmpty) {
      setState(() {
        isLoading = false; // Désactive le loader
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'Attention',
        desc: 'Tous les champs obligatoires doivent être remplis.',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
      return;
    }

    try {
      // Vérifier si un document avec le même ImobId existe déjà
      final QuerySnapshot existingImmobilisation = await FirebaseFirestore.instance
          .collection('Immobilisations')
          .where('ImobId', isEqualTo: imobId)
          .get();

      if (existingImmobilisation.docs.isNotEmpty) {
        // Si un document existe déjà avec le même ImobId, afficher un message d'erreur
        setState(() {
          isLoading = false; // Désactive le loader
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Duplication détectée',
          desc: 'Un document avec le numéro d\'immobilisation $imobId existe déjà.',
          btnOkOnPress: () {},
          width: 600,
          dialogBackgroundColor: Colors.white,
        ).show();
        return;
      }

      // Gestion de l'image de profil
      String? photoImob;
      if (_selectedImage != null) {
        final storageRef =
        FirebaseStorage.instance.ref('PhotosImmobilisations/$imobId.jpg');
        await storageRef.putData(_selectedImage!); // Utiliser putData pour Uint8List
        photoImob = await storageRef.getDownloadURL();
      }

      DocumentReference docRef =
      FirebaseFirestore.instance.collection('Immobilisations').doc();
      final Map<String, dynamic> immobilisation = {
        'docId': docRef.id,
        'ImobId': imobId,
        'photoImob': photoImob,
        'compteGeneral': compteGeneral,
        'famille': famille,
        'nomenclature': nomenclature,
        'emplacement': emplacement,
        'fournisseur': fournisseur,
        'valeurOrigine': valeurOrigine,
        'facture': facture,
        'affectataire': affectataire,
        'date': date,
        'duree': duree,
        'taux': taux,
        'ammorAnterieur': ammorAnterieur,
        'ammorCumul': ammorCumul,
        'ammorExercice': ammorExercice,
        'valeurNet': valeurNet,
        'dateCreation': formattedDate,
        'derniereModification': formattedDate,
      };

      await docRef.set(immobilisation);

      setState(() {
        isLoading = false; // Désactive le loader
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Succès',
        desc: 'Données ajoutées avec succès ! Numéro d\'immobilisation : $imobId',
        btnOkOnPress: () {
          _clearFields();
        },
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    } catch (e) {
      setState(() {
        isLoading = false; // Désactive le loader
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors de l\'ajout : $e',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    }
  }

  Future<void> _deleteImmobilisation(BuildContext context) async {
    setState(() {
      isLoading = true; // Active le loader
    });

    bool? confirmation = await AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      title: 'Confirmation',
      desc: 'Êtes-vous sûr de vouloir supprimer cette immobilisation ?',
      btnCancelOnPress: () {
        setState(() {
          isLoading = false; // Désactive le loader si annulé
        });
      },
      btnOkOnPress: () async {
        try {
          // Récupérer les données de l'immobilisation pour obtenir l'URL de l'image
          final docSnapshot = await FirebaseFirestore.instance
              .collection('Immobilisations')
              .doc(docId)
              .get();

          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            final String? photoImob = data?['photoImob'];

            // Supprimer la photo de Firebase Storage si elle existe
            if (photoImob != null && photoImob.isNotEmpty) {
              try {
                final storageRef = FirebaseStorage.instance.refFromURL(photoImob);
                await storageRef.delete();
                print('Photo supprimée avec succès : $photoImob');
              } catch (e) {
                print('Erreur lors de la suppression de la photo : $e');
              }
            }
          }

          // Supprimer le document Firestore
          await FirebaseFirestore.instance
              .collection('Immobilisations')
              .doc(docId)
              .delete();

          setState(() {
            isLoading = false; // Désactive le loader
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'Succès',
            desc: 'Immobilisation supprimée avec succès !',
            btnOkOnPress: () {},
            width: 600,
          ).show();
        } catch (e) {
          setState(() {
            isLoading = false; // Désactive le loader
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            title: 'Erreur',
            desc: 'Erreur lors de la suppression : $e',
            btnOkOnPress: () {},
            width: 600,
          ).show();
        }
      },
    ).show();
  }

  Future<void> _updateImmobilisationInFirestore(BuildContext context) async {
    // Récupérer les valeurs des champs
    final String imobId = _imobIdController.text.trim();
    final String compteGeneral = _compteGeneralController.text.trim();
    final String famille = _familleController.text.trim();
    final String nomenclature = _nomenclatureController.text.trim();
    final String emplacement = _emplacementController.text.trim();
    final String fournisseur = _fournisseurController.text.trim();
    final String valeurOrigine = _valeurOrigineController.text.trim();
    final String facture = _factureController.text.trim();
    final String affectataire = _affectataireController.text.trim();
    final String date = _dateController.text.trim();
    final String duree = _dureeController.text.trim();
    final String taux = _tauxController.text.trim();
    final String ammorAnterieur = _ammorAnterieurController.text.trim();
    final String ammorCumul = _ammorCumulController.text.trim();
    final String ammorExercice = _ammorExerciceController.text.trim();
    final String valeurNet = _valeurnetController.text.trim();

    final String formattedDate =
    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Vérifier que les champs essentiels ne sont pas vides
    if (docId.isEmpty ||
        imobId.isEmpty ||
        compteGeneral.isEmpty ||
        famille.isEmpty ||
        nomenclature.isEmpty ||
        emplacement.isEmpty ||
        fournisseur.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'Attention',
        desc: 'Tous les champs obligatoires doivent être remplis.',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
      return;
    }

    setState(() {
      isLoading = true; // Active le loader
    });

    // Gestion de l'image de profil
    String? photoImob;
    try {
      if (_selectedImage != null) {
        // Référence à l'image dans Firebase Storage
        final storageRef =
        FirebaseStorage.instance.ref('PhotosImmobilisations/$imobId.jpg');

        // Supprimer l'ancienne image si elle existe
        try {
          await storageRef.delete();
        } catch (e) {
          print('Aucune ancienne image à supprimer ou erreur : $e');
        }

        // Télécharger la nouvelle image
        await storageRef.putData(_selectedImage!); // Utiliser putData pour Uint8List
        photoImob = await storageRef.getDownloadURL();
      } else {
        // Si aucune nouvelle image n'est fournie, conserver l'ancienne URL
        final existingDoc = await FirebaseFirestore.instance
            .collection('Immobilisations')
            .doc(docId)
            .get();
        photoImob = existingDoc.data()?['photoImob'];
      }

      // Construire les données à mettre à jour
      final Map<String, dynamic> immobilisation = {
        'ImobId': imobId,
        'compteGeneral': compteGeneral,
        'famille': famille,
        'nomenclature': nomenclature,
        'emplacement': emplacement,
        'fournisseur': fournisseur,
        'valeurOrigine': valeurOrigine,
        'facture': facture,
        'affectataire': affectataire,
        'date': date,
        'duree': duree,
        'taux': taux,
        'ammorAnterieur': ammorAnterieur,
        'ammorCumul': ammorCumul,
        'ammorExercice': ammorExercice,
        'valeurNet': valeurNet,
        'photoImob': photoImob, // URL de l'image mise à jour ou conservée
        'derniereModification': formattedDate,
      };

      // Mettre à jour les données dans Firestore
      await FirebaseFirestore.instance
          .collection('Immobilisations')
          .doc(docId)
          .update(immobilisation);

      setState(() {
        isLoading = false; // Désactive le loader
      });

      // Afficher un message de succès
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Succès',
        desc: 'Données mises à jour avec succès pour le document',
        btnOkOnPress: () {
          _clearFields(); // Réinitialiser les champs après succès
        },
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    } catch (e) {
      setState(() {
        isLoading = false; // Désactive le loader
      });

      // Afficher un message d'erreur
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors de la mise à jour : $e',
        btnOkOnPress: () {},
        width: 600,
        dialogBackgroundColor: Colors.white,
      ).show();
    }
  }


// Fonction pour réinitialiser les champs
  // Fonction pour réinitialiser les champs
  void _clearFields() {
    _compteGeneralController.clear();
    _familleController.clear();
    _nomenclatureController.clear();
    _emplacementController.clear();
    _fournisseurController.clear();
    _valeurOrigineController.clear();
    _factureController.clear();
    _affectataireController.clear();
    _dateController.clear();
    _dureeController.clear();
    _tauxController.clear();
    _ammorAnterieurController.clear();
    _ammorCumulController.clear();
    _ammorExerciceController.clear();
    _valeurnetController.clear();
    _imobIdController.clear();
    _generateImobId();
  }
// Fonction pour construire un champ de texte
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData prefixIcon, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        required bool readOnly, // Paramètre requis pour gérer lecture seule
      }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly, // Rendre le champ en lecture seule si nécessaire
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
        fillColor: readOnly
            ? Colors.grey[200] // Couleur grisée si le champ est en lecture seule
            : Colors.white, // Couleur blanche sinon
        prefixIcon: Icon(prefixIcon, color: Colors.black),
      ),
    );
  }

// Ligne d'information
  Widget buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Non spécifié",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _generateImobId() {
    final String imobId = (1000 + Random().nextInt(9000)).toString(); // Génère un numéro entre 1000 et 9999
    _imobIdController.text = imobId; // Attribue cet ID au contrôleur
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
