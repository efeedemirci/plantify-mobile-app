import 'package:flutter/material.dart';
import 'tutorial_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPlantScreen extends StatelessWidget {
  const AddPlantScreen({super.key});

  Future<void> addPlantToMyPlants(Map<String, dynamic> plant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userPlantRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('my_plants')
        .doc(plant['name']);

    final int waterInterval = plant['waterIntervalDays'] ?? 3;
    final int sunHours = plant['sunExposureHours'] ?? 6;

    await userPlantRef.set({
      'name': plant['name'],
      'description': plant['description'],
      'image': plant['image'],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Bitki Ekle'), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plant_templates').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Şu anda hiç sabit bitki tanımlı değil.'));
          }

          final plants = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index].data() as Map<String, dynamic>;
              final waterInterval = plant['waterIntervalDays'] ?? 3;
              final sunHours = plant['sunExposureHours'] ?? 6;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/${plant['image']}',
                            fit: BoxFit.cover,
                            alignment: Alignment(0.0, -0.8),
                            errorBuilder: (context, _, __) =>
                            const Icon(Icons.local_florist, size: 80),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        plant['name'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plant['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text('💧 $waterInterval gün', style: const TextStyle(fontSize: 12)),
                      Text('☀️ $sunHours saat', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TutorialScreen(
                                plantData: plant,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ekle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
