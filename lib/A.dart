import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ImmobilisationDashboard extends StatefulWidget {
  @override
  _ImmobilisationDashboardState createState() =>
      _ImmobilisationDashboardState();
}

class _ImmobilisationDashboardState extends State<ImmobilisationDashboard> {
  String selectedCurrency = '\$';
  TextEditingController startDateController =
  TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  TextEditingController endDateController =
  TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  bool isFiltered = false;

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

  Stream<List<QueryDocumentSnapshot>> fetchImmobilisations() {
    Query query = FirebaseFirestore.instance.collection('Immobilisations');

    if (isFiltered) {
      DateTime? start = DateFormat('dd/MM/yyyy').parse(startDateController.text);
      DateTime? end = DateFormat('dd/MM/yyyy').parse(endDateController.text);
      query = query
          .where('dateCreation',
          isGreaterThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(start))
          .where('dateCreation',
          isLessThanOrEqualTo: DateFormat('dd/MM/yyyy HH:mm').format(end));
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  Widget buildDatePicker(
      TextEditingController controller,
      String label,
      IconData prefixIcon,
      ) {
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
        automaticallyImplyLeading: false,
        title: const Text('Tableau de Bord des Immobilisations'),
        backgroundColor: Colors.white,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.blueGrey),
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
}
