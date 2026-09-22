import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme.dart';
import 'registration_success_screen.dart';
import 'login_screen.dart';
import 'privacy_screen.dart';
import 'personal_screen.dart'; // ⭐ Dein persönlicher Bereich

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final nicknameController = TextEditingController();
  final birthdayController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String gender = "weiblich";
  String? errorMessage;
  bool _isLoading = false;

  bool _passwordVisible = false;
  bool _acceptedPrivacy = false;
  bool _stayLoggedIn = false;

  bool _validateFields() {
    if (firstnameController.text.trim().isEmpty ||
        lastnameController.text.trim().isEmpty ||
        nicknameController.text.trim().isEmpty ||
        birthdayController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Bitte fülle alle Pflichtfelder aus.";
      });
      return false;
    }

    if (!_acceptedPrivacy) {
      setState(() {
        errorMessage =
            "Bitte akzeptiere die Datenschutzvereinbarung und die Einwilligung zur Datenverarbeitung.";
      });
      return false;
    }

    return true;
  }

  Future<void> _register() async {
    if (_isLoading) return;
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        setState(() {
          errorMessage = "Registrierung fehlgeschlagen.";
          _isLoading = false;
        });
        return;
      }

      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "firstname": firstnameController.text.trim(),
        "lastname": lastnameController.text.trim(),
        "nickname": nicknameController.text.trim(),
        "birthday": birthdayController.text.trim(),
        "gender": gender,
        "email": emailController.text.trim(),
        "profileImage": null,
        "createdAt": DateTime.now(),
      });

      if (_stayLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("stayLoggedIn", true);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RegistrationSuccessScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Ein unbekannter Fehler ist aufgetreten.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ⭐ Zeile mit Pfeil links + Titel zentriert
              Row(
                children: [
                  // Latte-Pfeil links zurück zum persönlichen Bereich
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: LutaliaTheme.latte,
                      size: 22,
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    "Registrieren",
                    style: TextStyle(
                      fontFamily: "NewFirst",
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: LutaliaTheme.espresso,
                    ),
                  ),

                  const Spacer(),
                ],
              ),

              const SizedBox(height: 30),

              _buildInput("Vorname *", firstnameController),
              const SizedBox(height: 16),
              _buildInput("Nachname *", lastnameController),
              const SizedBox(height: 16),
              _buildInput("Nickname *", nicknameController),
              const SizedBox(height: 16),
              _buildInput("Geburtstag *", birthdayController),
              const SizedBox(height: 16),
              _buildInput("E-Mail *", emailController),
              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: "Passwort *",
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: LutaliaTheme.espresso,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ Datenschutzblock (DSGVO-konform)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LutaliaTheme.latte.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedPrivacy,
                      onChanged: (value) {
                        setState(() {
                          _acceptedPrivacy = value!;
                        });
                      },
                    ),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: "Cinzel",
                              fontSize: 14,
                              color: LutaliaTheme.espresso,
                            ),
                            children: [
                              TextSpan(
                                text: "Datenschutz & Einwilligung *\n",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text:
                                  "Ich habe die Datenschutzvereinbarung gelesen und stimme der Verarbeitung meiner personenbezogenen Daten gemäß Art. 6 Abs. 1 lit. a DSGVO zu.",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Checkbox(
                    value: _stayLoggedIn,
                    onChanged: (value) {
                      setState(() {
                        _stayLoggedIn = value!;
                      });
                    },
                  ),
                  const Text(
                    "Eingeloggt bleiben",
                    style: TextStyle(fontFamily: "Cinzel"),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LutaliaTheme.latte,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Registrieren",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Schon ein Konto? Einloggen",
                    style: TextStyle(
                      fontFamily: "Cinzel",
                      fontSize: 16,
                      color: LutaliaTheme.espresso,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
