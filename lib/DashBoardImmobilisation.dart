import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ImmobilisationDashboard extends StatefulWidget {
  bool administrateur = false;
  bool _isLoading = true; // Indicateur
  bool superadministrateur = false;
  User? currentUser;
  @override
  _ImmobilisationDashboardState createState() =>
      _ImmobilisationDashboardState();
}

class _ImmobilisationDashboardState extends State<ImmobilisationDashboard> {
  String selectedCurrency = '\$'; // Devise par défaut

  String nom = "";
  String postnom = "";
  String prenom = "";
  String email = "";
  String contact = "";
  String photoUrl = "";
  TextEditingController startDateController =
  TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  TextEditingController endDateController =
  TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  bool isFiltered = false; // Indique si une période a été sélectionnée
  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // Récupère les données utilisateur
  }
  Future<Map<String, dynamic>> fetchStats({DateTime? start, DateTime? end}) async {
    Query query = FirebaseFirestore.instance.collection('Immobilisations');

    if (start != null && end != null) {
      query = query
          .where('dateCreation',
          isGreaterThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(start))
          .where('dateCreation',
          isLessThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(end));
    }

    QuerySnapshot querySnapshot = await query.get();

    int totalImmobilisations = querySnapshot.docs.length;
    double totalValeurOrigine = 0.0;
    double totalValeurNet = 0.0;
    double totalAmmorExercice = 0.0;
    double totalCumul = 0.0;
    Set<String> familles = {};

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      totalValeurOrigine += double.tryParse(data['valeurOrigine'] ?? '0') ?? 0.0;
      totalValeurNet += double.tryParse(data['valeurNet'] ?? '0') ?? 0.0;
      totalAmmorExercice += double.tryParse(data['ammorExercice'] ?? '0') ?? 0.0;
      totalCumul += double.tryParse(data['ammorCumul'] ?? '0') ?? 0.0;

      if (data['famille'] != null) familles.add(data['famille']);
    }

    return {
      'totalImmobilisations': totalImmobilisations,
      'totalValeurOrigine': totalValeurOrigine,
      'totalValeurNet': totalValeurNet,
      'totalAmmorExercice': totalAmmorExercice,
      'totalCumul': totalCumul,
      'familles': familles.length,
    };
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

      });
    }
  }

  Stream<List<QueryDocumentSnapshot>> fetchImmobilisations() {
    Query query = FirebaseFirestore.instance.collection('Immobilisations');

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
          'TABLEAU DE BORD',
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
                                print("Déconnexion...");
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
                  value: selectedCurrency,
                  items: ['\$', '€', '£', 'CFA'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedCurrency = newValue!;
                    });
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
                          'Total Immobilisations',
                          '${stats['totalImmobilisations']}',
                          Colors.teal,
                          Icons.inventory_2_outlined,
                        ),
                        _buildStatCard(
                          'Familles Distinctes',
                          '${stats['familles']}',
                          Colors.orange,
                          Icons.category_outlined,
                        ),
                        _buildStatCard(
                          'Valeur Origine',
                          '${stats['totalValeurOrigine'].toStringAsFixed(2)} $selectedCurrency',
                          Colors.blue,
                          Icons.monetization_on_outlined,
                        ),
                        _buildStatCard(
                          'Valeur Nette',
                          '${stats['totalValeurNet'].toStringAsFixed(2)} $selectedCurrency',
                          Colors.green,
                          Icons.attach_money_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Amortissement Exercice',
                          '${stats['totalAmmorExercice'].toStringAsFixed(2)} $selectedCurrency',
                          Colors.purple,
                          Icons.trending_down_outlined,
                        ),
                        _buildStatCard(
                          'Valeur Cumulée',
                          '${stats['totalCumul'].toStringAsFixed(2)} $selectedCurrency',
                          Colors.red,
                          Icons.bar_chart_outlined,
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
                stream: fetchImmobilisations(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  var immobilisations = snapshot.data!;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Famille')),
                        DataColumn(label: Text('Nomenclature')),
                        DataColumn(label: Text('Valeur Origine')),
                        DataColumn(label: Text('Valeur Nette')),
                      ],
                      rows: immobilisations.map((immobilisation) {
                        var data = immobilisation.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(data['famille'] ?? 'N/A')),
                            DataCell(Text(data['nomenclature'] ?? 'N/A')),
                            DataCell(Text(
                                '${data['valeurOrigine'] ?? 0} $selectedCurrency')),
                            DataCell(Text(
                                '${data['valeurNet'] ?? 0} $selectedCurrency')),
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
