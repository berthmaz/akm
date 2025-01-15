import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CoursDashboard extends StatefulWidget {
  bool administrateur = false;
  bool _isLoading = true; // Indicateur
  bool superadministrateur = false;
  User? currentUser;

  @override
  _CoursDashboardState createState() => _CoursDashboardState();
}

class _CoursDashboardState extends State<CoursDashboard> {
  String? _selectedSection;
  String? _selectedOption;
  String? _selectedPromotion;
  bool isFiltered = false;

  TextEditingController startDateController =
  TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  TextEditingController endDateController =
  TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  String nom = "";
  String postnom = "";
  String prenom = "";
  String email = "";
  String contact = "";
  String photoUrl = "";

  final List<String> sections = [
    'Sciences Infirmières',
    'Sage-femme',
    'Gestion de Techniques Biomédicales',
  ];

  final List<String> options = [
    'Hospitalière',
    'Soins Généraux',
    'Sage-femme (Accouchement)',
    'Enseignement et Administration en Soins Infirmiers (E.A.S.I)',
    'Gestion des Institutions de Santé (G.I.S)',
    'Techniques de Laboratoire',
    'Nutrition-Diététique',
    'Pédiatrie',
    'Neuropsychiatrie',
    'Santé Communautaire',
  ];

  final List<String> promotions = [
    'LICENCE 1',
    'LICENCE 2',
    'LICENCE 3',
    'MASTER 1',
    'MASTER 2',
  ];

  @override
  void initState() {
    super.initState();
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
        widget._isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchStats({DateTime? start, DateTime? end}) async {
    Query query = FirebaseFirestore.instance.collection('Cours');

    if (start != null && end != null) {
      query = query
          .where('dateCreation',
          isGreaterThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(start))
          .where('dateCreation',
          isLessThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(end));
    }

    QuerySnapshot querySnapshot = await query.get();

    int totalCours = querySnapshot.docs.length;
    int coursParSection = _selectedSection != null ? totalCours : 0;
    int coursParOption = _selectedOption != null ? totalCours : 0;
    int coursParPromotion = _selectedPromotion != null ? totalCours : 0;
    int coursParEnseignant = 0; // À implémenter selon votre logique

    return {
      'totalCours': totalCours,
      'coursParSection': coursParSection,
      'coursParOption': coursParOption,
      'coursParPromotion': coursParPromotion,
      'coursParEnseignant': coursParEnseignant,
    };
  }

  Stream<List<QueryDocumentSnapshot>> fetchCours() {
    Query query = FirebaseFirestore.instance.collection('Cours');

    if (isFiltered && startDateController.text.isNotEmpty && endDateController.text.isNotEmpty) {
      DateTime start = DateFormat('dd/MM/yyyy').parse(startDateController.text);
      DateTime end = DateFormat('dd/MM/yyyy').parse(endDateController.text);
      query = query
          .where('dateCreation',
          isGreaterThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(start))
          .where('dateCreation',
          isLessThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(end));
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  Widget buildDatePicker(
      TextEditingController controller, String label, IconData prefixIcon) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
          borderRadius: BorderRadius.circular(15.0),
        ),
        filled: true,
        fillColor: Colors.teal.shade50,
        prefixIcon: Icon(prefixIcon, color: Colors.teal),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2101),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.teal,
                hintColor: Colors.teal,
                buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
          setState(() {
            isFiltered = startDateController.text.isNotEmpty &&
                endDateController.text.isNotEmpty;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5DADE2), // Couleur bleue du logo
        title: const Text(
          'TABLEAU DE BORD DES COURS',
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
                      color: Colors.yellow,
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
                                // Action de déconnexion
                                FirebaseAuth.instance.signOut();
                                Navigator.of(context).pop();
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: buildDatePicker(
                      startDateController, 'Début', Icons.calendar_today),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildDatePicker(
                      endDateController, 'Fin', Icons.calendar_today),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: '\$',
                  items: ['\$', '€', '£', 'CFA'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: fetchStats(
                start: isFiltered
                    ? DateFormat('dd/MM/yyyy').parse(startDateController.text)
                    : null,
                end: isFiltered
                    ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
                    : null,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var stats = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Total Cours',
                          '${stats['totalCours']}',
                          Colors.teal,
                          Icons.book,
                        ),
                        _buildStatCard(
                          'Cours par Section',
                          '${stats['coursParSection']}',
                          Colors.orange,
                          Icons.category,
                        ),
                        _buildStatCard(
                          'Cours par Option',
                          '${stats['coursParOption']}',
                          Colors.blue,
                          Icons.list,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Cours par Promotion',
                          '${stats['coursParPromotion']}',
                          Colors.green,
                          Icons.school,
                        ),
                        _buildStatCard(
                          'Cours par Enseignant',
                          '${stats['coursParEnseignant']}',
                          Colors.purple,
                          Icons.person,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<QueryDocumentSnapshot>>(
                stream: fetchCours(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  var cours = snapshot.data!;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Intitulé du Cours')),
                        DataColumn(label: Text('Section')),
                        DataColumn(label: Text('Option')),
                        DataColumn(label: Text('Promotion')),
                        DataColumn(label: Text('Enseignant')),
                      ],
                      rows: cours.map((coursDoc) {
                        var data = coursDoc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(data['intituleCours'] ?? 'N/A')),
                            DataCell(Text(data['section'] ?? 'N/A')),
                            DataCell(Text(data['option'] ?? 'N/A')),
                            DataCell(Text(data['promotion'] ?? 'N/A')),
                            DataCell(Text(data['enseignant'] ?? 'N/A')),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
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
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}