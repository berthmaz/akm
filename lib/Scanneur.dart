import 'package:flutter/material.dart';
import 'package:flutter_web_qrcode_scanner/flutter_web_qrcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isScanning = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner un code QR',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.blueGrey),
      ),
      body: _isScanning ? _buildScanningView() : _buildResultView(),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FlutterWebQrcodeScanner(
              cameraDirection: CameraDirection.back,
              onGetResult: (result) async {
                setState(() {
                  _isScanning = false;
                });

                // Vérifier et récupérer les informations dans Firestore
                await _processScannedQRCode(result, context);
              },
              stopOnFirstResult: true,
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              onError: (error) {
                setState(() {
                  _isScanning = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: ${error.message}")),
                );
              },
              onPermissionDeniedError: () {
                setState(() {
                  _isScanning = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Permission refusée. Activez l'accès à la caméra.",
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _isScanning = false;
              });
            },
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 300,
            color: Colors.teal,
          ),
          const SizedBox(height: 16),
          const Text(
            'Appuyez sur le bouton pour démarrer le scanner',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.greenAccent, width: 2),
              ),
              shadowColor: Colors.greenAccent.withOpacity(0.5),
              elevation: 8,
            ),
            onPressed: () {
              setState(() {
                _isScanning = true;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow, size: 24, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Démarrer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _processScannedQRCode(String scannedValue, BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Immobilisations')
          .where('docId', isEqualTo: scannedValue)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        Map<String, dynamic> immobilisationData = {
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
          'ammorCumul': doc['ammorCumul'] ?? '',
          'ammorExercice': doc['ammorExercice'] ?? '',
          'valeurNet': doc['valeurNet'] ?? '',
          'dateCreation': doc['dateCreation'] ?? '',
          'derniereModification': doc['derniereModification'] ?? '',
          'photoImob': doc['photoImob'] ?? '',
        };
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(result: immobilisationData),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          title: 'Échec',
          desc: 'Le code scanné n’a pas été reconnu.',
          btnOkOnPress: () {},
          width: 600,
          btnOkColor: Colors.red,
        ).show();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'Erreur',
        desc: 'Erreur lors de la recherche : $e',
        btnOkOnPress: () {},
        width: 600,
        btnOkColor: Colors.red,
      ).show();
    }
  }
}

class ResultPage extends StatelessWidget {
  final Map<String, dynamic>? result;

  const ResultPage({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, dynamic>> entries = result?.entries.toList() ?? [];
    final bool isSuccess = result != null && (result?.isNotEmpty ?? false);
    final String? photoUrl = result?['photoImob'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MODULE : RÉSULTAT',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSuccess ? 'SUCCÈS' : 'CARTE REFUSÉE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (isSuccess && photoUrl != null && photoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photoUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 200, color: Colors.grey);
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                  (progress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (isSuccess)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    for (int i = 0; i < entries.length; i += 4)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            for (int j = 0; j < 4; j++)
                              if (i + j < entries.length)
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 6.0, horizontal: 8.0),
                                              isDense: true,
                                              labelText: _getFullFieldName(entries[i + j].key),
                                              labelStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                              prefixIcon: Icon(
                                                _getIcon(entries[i + j].key),
                                                color: Colors.teal,
                                                size: 18,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                  width: 1.0,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                  width: 1.0,
                                                ),
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            controller: TextEditingController(
                                              text: entries[i + j].value?.toString() ?? '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFullFieldName(String key) {
    switch (key) {
      case 'ammorCumul':
        return 'AMORTISSEMENT CUMULÉ';
      case 'ammorExercice':
        return 'AMORTISSEMENT DE L’EXERCICE';
      case 'ammorAnterieur':
        return 'AMORTISSEMENT ANTÉRIEUR';
      case 'valeurOrigine':
        return 'VALEUR D’ORIGINE';
      case 'valeurNet':
        return 'VALEUR NETTE';
      case 'dateCreation':
        return 'DATE DE CRÉATION';
      case 'derniereModification':
        return 'DATE DE DERNIÈRE MODIFICATION';
      case 'famille':
        return 'FAMILLE';
      case 'emplacement':
        return 'EMPLACEMENT';
      case 'fournisseur':
        return 'FOURNISSEUR';
      case 'facture':
        return 'FACTURE';
      case 'taux':
        return 'TAUX';
      case 'nomenclature':
        return 'NOMENCLATURE';
      default:
        return key.toUpperCase(); // Retourne le nom en majuscules si aucun label spécifique n'est défini.
    }
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'famille':
        return Icons.family_restroom;
      case 'emplacement':
        return Icons.location_on;
      case 'fournisseur':
        return Icons.store;
      case 'valeurOrigine':
        return Icons.attach_money;
      case 'facture':
        return Icons.receipt_long;
      case 'date':
        return Icons.calendar_today;
      case 'taux':
        return Icons.percent;
      default:
        return Icons.info_outline;
    }
  }
}

