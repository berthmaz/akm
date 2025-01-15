import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
class CreerComptePage extends StatefulWidget {
  @override
  _CreerComptePageState createState() => _CreerComptePageState();
}

class _CreerComptePageState extends State<CreerComptePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _confirmerMotDePasseController =
  TextEditingController();
  bool _isLoading = false;
  Uint8List? _selectedImage; // Compatible avec Flutter Web
  final ImagePicker _picker = ImagePicker();
  bool _obscurePassword = true; // Variable pour masquer/afficher le mot de passe
  bool _obscureConfirmPassword = true; // Variable

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





  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;

    if (_motDePasseController.text != _confirmerMotDePasseController.text) {
      _showDialog(
        DialogType.warning,
        "Erreur",
        "Les mots de passe ne correspondent pas.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Création de l'utilisateur avec FirebaseAuth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _motDePasseController.text.trim(),
      );

      // Gestion de l'image de profil
      String? photoUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref('PhotosProfil/${userCredential.user!.uid}.jpg');
        await storageRef.putData(_selectedImage!); // Utiliser putData pour Uint8List
        photoUrl = await storageRef.getDownloadURL();
      }

      // Enregistrement des informations utilisateur dans Firestore
      await FirebaseFirestore.instance.collection('Utilisateurs').doc(userCredential.user!.uid).set({
        "userId": userCredential.user!.uid, // Enregistrement du userId
        "administrateur": false,
        "bloquer": false,
        "superadministrateur": false,
        "photoUrl": photoUrl,
        "nom": _nomController.text.trim(),
        "prenom": _prenomController.text.trim(),
        "email": _emailController.text.trim(),
        "contact": _contactController.text.trim(),
        "motDePasse": _motDePasseController.text.trim(),
      });

      // Affichage du message de succès
      _showDialog(
        DialogType.success,
        "Succès",
        "Votre compte a été créé avec succès.",
        onOkPress: () => Navigator.pop(context),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs FirebaseAuth
      _showDialog(
        DialogType.error,
        "Erreur",
        e.message ?? "Une erreur est survenue.",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(DialogType type, String title, String desc,
      {VoidCallback? onOkPress}) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.topSlide,
      title: title,
      desc: desc,
      width: 600, // Largeur des boîtes de dialogue
      btnOkOnPress: onOkPress ?? () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Créer un compte",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5DADE2),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              color: const Color(0xFFF0F4F8), // Fond gris clair
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: 500, // Ajuste la largeur du formulaire
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage, // Sélection d'image
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.indigo,
                                backgroundImage: _selectedImage != null
                                    ? MemoryImage(_selectedImage!) // Affiche l'image sélectionnée
                                    : null,
                                child: _selectedImage == null
                                    ? const Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Champs "Nom" et "Prénom" côte à côte
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _nomController,
                                    label: "Nom",
                                    icon: Icons.person,
                                  ),
                                ),
                                const SizedBox(width: 20), // Espacement entre les champs
                                Expanded(
                                  child: _buildTextField(
                                    controller: _prenomController,
                                    label: "Prénom",
                                    icon: Icons.person,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Champs "Email" et "Contact" côte à côte
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _emailController,
                                    label: "Email",
                                    icon: Icons.email,
                                  ),
                                ),
                                const SizedBox(width: 20), // Espacement entre les champs
                                Expanded(
                                  child: _buildTextField(
                                    controller: _contactController,
                                    label: "Contact",
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Champs "Mot de passe" et "Confirmer le mot de passe" côte à côte
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _motDePasseController,
                                    label: "Mot de passe",
                                    icon: Icons.lock,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _confirmerMotDePasseController,
                                    label: "Confirmer",
                                    icon: Icons.lock,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Bouton de création de compte
                            _isLoading
                                ? const SpinKitCircle(
                              color: Colors.orange,
                              size: 50.0,
                            )
                                : ElevatedButton(
                              onPressed: _creerCompte,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DADE2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                minimumSize: const Size.fromHeight(50),
                                elevation: 5,
                              ),
                              child: const Text(
                                "Créer un compte",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Fond semi-transparent
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: "Entrez votre $label",
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5DADE2)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Veuillez remplir ce champ.";
        }
        return null;
      },
    );
  }
}
