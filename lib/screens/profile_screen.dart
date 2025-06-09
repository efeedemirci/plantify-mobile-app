import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String surname = '';
  int xp = 0;
  int dailyStreak = 0;
  bool isLoading = true;
  File? _localProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocalImage();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = data['name'] ?? '';
        surname = data['surname'] ?? '';
        xp = data['xp'] ?? 0;
        dailyStreak = data['dailyStreak'] ?? 0;
        isLoading = false;
      });
    }
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _localProfileImage = File(imagePath);
      });
    }
  }

  Future<void> _pickAndSavePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Kırp',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.green,
        ),
      ],
    );

    if (cropped == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/profile_image.jpg';
    final imageFile = File(cropped.path);
    await imageFile.copy(path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);

    setState(() {
      _localProfileImage = File(path);
    });
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');

    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        await file.delete();
      }
      await prefs.remove('profile_image_path');
    }

    setState(() {
      _localProfileImage = null;
    });
  }

  Future<void> _incrementXP() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.update({
      'xp': xp + 10,
      'dailyStreak': dailyStreak + 1,
    });

    await _loadUserData();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bakım yapıldı! XP +10")),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.green.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _localProfileImage != null
                  ? FileImage(_localProfileImage!)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
              backgroundColor: Colors.greenAccent,
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                ElevatedButton(
                  onPressed: _pickAndSavePhoto,
                  child: const Text("Fotoğrafa Ekle / Değiştir"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _removePhoto,
                  child: const Text("Fotoğrafı Kaldır"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$name $surname',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'XP: $xp | Günlük Seri: $dailyStreak gün',
                style: TextStyle(color: Colors.green.shade900),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _incrementXP,
              icon: const Icon(Icons.local_florist),
              label: const Text("Bakım Yaptım (XP +10)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text("Çıkış Yap"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}