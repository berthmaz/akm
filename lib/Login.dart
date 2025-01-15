import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'Acceuil.dart'; // Page d'accueil après connexion
import 'CreerCompte.dart'; // Page de création de compte

class ConnexionPage extends StatefulWidget {
  @override
  _ConnexionPageState createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _seConnecter() async {
    String email = _emailController.text.trim();
    String motDePasse = _motDePasseController.text.trim();

    if (email.isEmpty || motDePasse.isEmpty) {
      _showDialog(
        DialogType.warning,
        "Attention",
        "Veuillez entrer votre email et mot de passe.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final utilisateursQuery = await FirebaseFirestore.instance
          .collection('Utilisateurs')
          .where('email', isEqualTo: email)
          .where('motDePasse', isEqualTo: motDePasse)
          .get();

      if (utilisateursQuery.docs.isEmpty) {
        _showDialog(DialogType.error, "Erreur", "Informations invalides.");
        return;
      }

      await _auth.signInWithEmailAndPassword(email: email, password: motDePasse);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AcceuilPage()),
      );
    } on FirebaseAuthException catch (e) {
      _showDialog(
        DialogType.error,
        "Erreur",
        _getFirebaseErrorMessage(e.code),
      );
    } catch (e) {
      _showDialog(
        DialogType.error,
        "Erreur",
        "Une erreur inattendue est survenue. Veuillez réessayer.",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(DialogType type, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.topSlide,
      title: title,
      desc: desc,
      width: 600, // Largeur des boîtes de dialogue fixée à 600
      btnOkOnPress: () {},
    ).show();
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cet email.";
      case 'wrong-password':
        return "Le mot de passe est incorrect.";
      default:
        return "Une erreur est survenue.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Connectez-vous",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5DADE2), // Couleur bleue du logo
        centerTitle: true,
        elevation: 5,
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF0F4F8), // Fond gris très clair
            child: Center(
              child: Card(
                color: Colors.white, // Carte blanche
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/akm.png', // Votre logo
                          height: 150, // Taille ajustée
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 15),
                        _buildPasswordField(),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const SizedBox() // On affiche l'animation au-dessus avec Stack
                            : ElevatedButton(
                          onPressed: _seConnecter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5DADE2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize: const Size.fromHeight(50),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Se connecter",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Action pour "Mot de passe oublié ?"
                              },
                              child: const Text(
                                "Mot de passe oublié ?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5DADE2), // Bleu clair
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CreerComptePage()),
                                );
                              },
                              child: const Text(
                                "Créer un compte",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5DADE2), // Bleu clair
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  color: Colors.orange, // Spinner orange
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "Entrez votre $label",
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5DADE2)),
        filled: true,
        fillColor: const Color(0xFFF7F9FA), // Fond gris clair
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _motDePasseController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: "Entrez votre mot de passe",
        labelText: "Mot de passe",
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF5DADE2)),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF5DADE2),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9FA), // Fond gris clair
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
