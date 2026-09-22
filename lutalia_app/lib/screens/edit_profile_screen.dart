import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/theme.dart';
import 'lutalia_page.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final nicknameController = TextEditingController();
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();
  final genderController = TextEditingController();
  final passwordController = TextEditingController();

  String? profileImageUrl;
  bool loading = true;
  File? newImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final data = doc.data() ?? {};

    nicknameController.text = data["nickname"] ?? "";
    firstnameController.text = data["firstname"] ?? "";
    lastnameController.text = data["lastname"] ?? "";
    emailController.text = data["email"] ?? "";
    birthdayController.text = data["birthday"] ?? "";
    genderController.text = data["gender"] ?? "";

    profileImageUrl = data["profileImage"];

    print("🔥 GELADENES PROFILBILD: $profileImageUrl");

    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked == null) {
      print("❌ Kein Bild ausgewählt");
      return;
    }

    newImageFile = File(picked.path);

    print("📸 Neues Bild ausgewählt: ${newImageFile!.path}");

    setState(() {});
  }

  Future<String?> _uploadProfileImage() async {
    if (newImageFile == null) {
      print("⚠️ Kein neues Bild zum Hochladen");
      return profileImageUrl;
    }

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child("${user!.uid}.jpg");

      print("⬆️ Lade Bild hoch...");

      await ref.putFile(newImageFile!);

      final url = await ref.getDownloadURL();

      print("✅ Upload erfolgreich: $url");

      return url;
    } catch (e) {
      print("❌ Upload Fehler: $e");
      return profileImageUrl;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => loading = true);

    final imageUrl = await _uploadProfileImage();

    print("💾 Speichere Profilbild in Firestore: $imageUrl");

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
      "nickname": nicknameController.text.trim(),
      "firstname": firstnameController.text.trim(),
      "lastname": lastnameController.text.trim(),
      "email": emailController.text.trim(),
      "birthday": birthdayController.text.trim(),
      "gender": genderController.text.trim(),
      "profileImage": imageUrl,
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return LutaliaPage(
      title: "Profil bearbeiten",
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: LutaliaTheme.espresso),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              children: [
                const SizedBox(height: 10),

                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFD8C3B8),
                        backgroundImage: newImageFile != null
                            ? FileImage(newImageFile!)
                            : (profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null),
                        child: (newImageFile == null &&
                                profileImageUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: LutaliaTheme.espresso,
                              )
                            : null,
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _pickImage,
                        child: const Text(
                          "Profilbild ändern",
                          style: TextStyle(
                            fontFamily: "Cinzel",
                            fontSize: 16,
                            color: LutaliaTheme.espresso,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                _field("Nickname", nicknameController),
                _field("Vorname", firstnameController),
                _field("Nachname", lastnameController),
                _field("E-Mail", emailController),
                _field("Geburtstag", birthdayController),
                _field("Geschlecht", genderController),

                _field("Passwort ändern (optional)", passwordController, obscure: true),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LutaliaTheme.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Speichern",
                      style: TextStyle(
                        fontFamily: "Cinzel",
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: "Cinzel",
            fontSize: 16,
            color: LutaliaTheme.espresso,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: LutaliaTheme.espresso),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: LutaliaTheme.espresso, width: 1.4),
          ),
        ),
      ),
    );
  }
}
