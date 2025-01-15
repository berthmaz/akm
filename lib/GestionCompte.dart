import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DashBoardUser.dart';

class GestionComptesPage extends StatefulWidget {
  const GestionComptesPage({super.key});

  @override
  _GestionComptesPageState createState() => _GestionComptesPageState();
}

class _GestionComptesPageState extends State<GestionComptesPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _numCompteGeneralController = TextEditingController();
  final TextEditingController _IntituleController = TextEditingController();

  bool isLoading = false;
  String docId = '';

  List<Map<String, dynamic>> comptes = [];

  @override
  void initState() {
    super.initState();
    fetchComptes();
  }

  Future<void> fetchComptes() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Comptes').get();

      List<Map<String, dynamic>> comptesList = querySnapshot.docs.map((doc) {
        return {
          'docId': doc.id,
          'compteGeneral': doc['compteGeneral'] ?? '',
          'intituleCompte': doc['intituleCompte'] ?? '',
        };
      }).toList();

      setState(() {
        comptes = comptesList;
      });
    } catch (e) {
      print('Erreur lors de la récupération des comptes: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Impossible de récupérer les comptes.',
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Module : Gérer comptes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 2.5,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 8,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.blueGrey),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.blueGrey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashBoardUser()),
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
                  _buildUserInfoForm(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 20),
                  userListWidget(),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: SpinKitCircle(
                  color: Colors.orange,
                  size: 70.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget userListWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (searchTerm) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Rechercher le compte...",
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, // Assure que la Card prend toute la largeur disponible
            child: Card(
              elevation: 8,
              shadowColor: Colors.grey.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: StreamBuilder<List<QueryDocumentSnapshot>>(
                stream: _searchUser(_searchController.text),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Aucun compte trouvé",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }

                  var comptesStream = snapshot.data!;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowHeight: 56,
                      dataRowHeight: 60,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('N° Compte Général', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Intitulé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      ],
                      rows: comptesStream.map((compte) {
                        var compteData = compte.data() as Map<String, dynamic>;

                        return DataRow(cells: [
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editUser(compteData),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(compteData['compteGeneral'] ?? '', style: const TextStyle(fontSize: 14))),
                          DataCell(Text(compteData['intituleCompte'] ?? '', style: const TextStyle(fontSize: 14))),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _editUser(Map<String, dynamic> compteData) {
    _numCompteGeneralController.text = compteData['compteGeneral'] ?? '';
    _IntituleController.text = compteData['intituleCompte'] ?? '';
    docId = compteData['compteGeneral'] ?? '';
  }

  Stream<List<QueryDocumentSnapshot>> _searchUser(String searchTerm) async* {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (searchTerm.isEmpty) {
      // Si aucun terme n'est saisi, retourner tous les comptes
      yield* firestore.collection('Comptes').snapshots().map((snapshot) => snapshot.docs);
    } else {
      // Convertir le terme de recherche en minuscule
      String normalizedSearchTerm = searchTerm.toLowerCase();

      // Filtrer les documents localement après récupération
      yield* firestore.collection('Comptes').snapshots().map((snapshot) {
        return snapshot.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String compteGeneral = (data['compteGeneral'] ?? '').toString().toLowerCase();
          String intituleCompte = (data['intituleCompte'] ?? '').toString().toLowerCase();

          // Vérification si le terme saisi correspond au compteGeneral ou intituleCompte
          return compteGeneral.contains(normalizedSearchTerm) || intituleCompte.contains(normalizedSearchTerm);
        }).toList();
      });
    }
  }

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
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _numCompteGeneralController,
                    'N° Compte Général',
                    Icons.account_balance,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _IntituleController,
                    'Intitulé compte',
                    Icons.category,
                    readOnly: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData prefixIcon, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        required bool readOnly,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
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
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
        prefixIcon: Icon(prefixIcon, color: Colors.black),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                _addCompteToFirestore(context);
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
                _updateCompteInFirestore(context);
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
                _deleteCompte(context);
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
          ],
        ),
      ),
    );
  }

  void _addCompteToFirestore(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    final String compteGeneral = _numCompteGeneralController.text.trim();
    final String intituleCompte = _IntituleController.text.trim();

    if (compteGeneral.isEmpty || intituleCompte.isEmpty) {
      setState(() {
        isLoading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'Attention',
        desc: 'Tous les champs obligatoires doivent être remplis.',
        btnOkOnPress: () {},
        width: 600,
      ).show();
      return;
    }

    try {
      final Map<String, dynamic> compte = {
        'compteGeneral': compteGeneral,
        'intituleCompte': intituleCompte,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('Comptes').doc(compteGeneral).set(compte);

      setState(() {
        isLoading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Succès',
        desc: 'Compte ajouté avec succès !',
        width: 600,
        btnOkOnPress: () {
          _clearFields();
        },
      ).show();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Erreur',
        desc: 'Erreur lors de l\'ajout : $e',
        width: 600,
        btnOkOnPress: () {},
      ).show();
    }
  }

  void _deleteCompte(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.rightSlide,
      title: 'Confirmation',
      desc: 'Êtes-vous sûr de vouloir supprimer ce compte ?',
      width: 600,
      btnCancelOnPress: () {
        setState(() {
          isLoading = false;
        });
      },
      btnOkOnPress: () async {
        try {
          await FirebaseFirestore.instance.collection('Comptes').doc(docId).delete();

          setState(() {
            isLoading = false;
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'Succès',
            desc: 'Compte supprimé avec succès !',
            width: 600,
            btnOkOnPress: () {},
          ).show();
        } catch (e) {
          setState(() {
            isLoading = false;
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            title: 'Erreur',
            desc: 'Erreur lors de la suppression : $e',
            width: 600,
            btnOkOnPress: () {},
          ).show();
        }
      },
    ).show();
  }

  Future<void> _updateCompteInFirestore(BuildContext context) async {
    final String compteGeneral = _numCompteGeneralController.text.trim();
    final String intituleCompte = _IntituleController.text.trim();

    if (docId.isEmpty || compteGeneral.isEmpty || intituleCompte.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        title: 'Attention',
        desc: 'Tous les champs obligatoires doivent être remplis.',
        width: 600,
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() {
      isLoading = true;
    });

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.rightSlide,
      title: 'Confirmation',
      desc: 'Êtes-vous sûr de vouloir modifier ce compte ?',
      width: 600,
      btnCancelOnPress: () {
        setState(() {
          isLoading = false;
        });
      },
      btnOkOnPress: () async {
        final Map<String, dynamic> compte = {
          'compteGeneral': compteGeneral,
          'intituleCompte': intituleCompte,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        try {
          await FirebaseFirestore.instance.collection('Comptes').doc(compteGeneral).update(compte);

          setState(() {
            isLoading = false;
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Succès',
            desc: 'Données mises à jour avec succès.',
            width: 600,
            btnOkOnPress: () {
              _clearFields();
            },
          ).show();
        } catch (e) {
          setState(() {
            isLoading = false;
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.rightSlide,
            title: 'Erreur',
            desc: 'Erreur lors de la mise à jour : $e',
            width: 600,
            btnOkOnPress: () {},
          ).show();
        }
      },
    ).show();
  }

  void _clearFields() {
    _numCompteGeneralController.clear();
    _IntituleController.clear();
    docId = '';
  }
}
