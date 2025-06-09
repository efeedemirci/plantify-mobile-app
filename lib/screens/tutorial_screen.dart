import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';

class TutorialScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;

  const TutorialScreen({super.key, required this.plantData});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int currentStep = 0;

  late final List<Map<String, String>> tutorialSteps;
  late final String plantName;
  late final String plantImage;

  @override
  void initState() {
    super.initState();
    plantName = widget.plantData['name'] ?? 'Bitki';
    plantImage = widget.plantData['image'] ?? '';

    tutorialSteps = [
      {
        "text": "Toprak dolusu bir saksıya tohumunu nazikçe ek!",
        "image": "assets/plantinpot.png",
      },
      {
        "text": "Toprağını sevgiyle sula, onu canlandır!",
        "image": "assets/water.png",
      },
      {
        "text": "Güneşin sıcaklığıyla büyümesine izin ver!",
        "image": "assets/sunlight.png",
      },
      {
        "text": "Harika!\n Şimdi $plantName Yetiştirme Zamanı! 🌱",
        "image": "assets/grow.gif",
      },
    ];
  }

  void goNext() async {
    if (currentStep < tutorialSteps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      await addPlantToUser();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void goBack() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  Future<void> addPlantToUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final plantRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('my_plants')
        .doc(plantName);

    final int waterInterval = widget.plantData['waterIntervalDays'] ?? 3;
    final int sunHours = widget.plantData['sunExposureHours'] ?? 6;

    await plantRef.set({
      'name': plantName,
      'description': widget.plantData['description'] ?? '',
      'image': plantImage,
      'health': 'İyi',
      'addedAt': Timestamp.now(),
      'waterIntervalDays': waterInterval,
      'sunExposureHours': sunHours,
      'nextWaterTime': Timestamp.fromDate(DateTime.now().add(Duration(days: waterInterval))),
      'nextSunTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: sunHours))),
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = tutorialSteps[currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCF8),
      appBar: AppBar(
        title: Text(
          "🌱 Bitki Yetiştirme Rehberi",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Görsel Kart
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                step['image']!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bilgilendirici Metin
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              step['text']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Mini İpucu kutusu (ekstra içerik için)
          if (currentStep != tutorialSteps.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF5E1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "💡 İpucu: Bitkiler düzenli ilgiyle daha hızlı gelişir!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF1B5E20)),
                ),
              ),
            ),

          const Spacer(),

          // Adım bilgisi
          Text(
            "${currentStep + 1} / ${tutorialSteps.length}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // Butonlar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                currentStep > 0
                    ? ElevatedButton.icon(
                  onPressed: goBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Geri"),
                )
                    : const SizedBox(width: 120),

                ElevatedButton.icon(
                  onPressed: goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    currentStep == tutorialSteps.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    currentStep == tutorialSteps.length - 1 ? "Bitir" : "İleri",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
