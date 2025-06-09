import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';
import '../notification_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const PlantDetailScreen({super.key, required this.plantData});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late DateTime nextWaterTime;
  late DateTime sunStartTime;
  late int waterIntervalDays;
  late int sunExposureHours;
  late String health;
  late String docId;

  Timer? _timer;
  Duration _remainingWater = Duration.zero;
  Duration _remainingSun = Duration.zero;

  @override
  void initState() {
    super.initState();
    docId = widget.plantData['id'] ?? '';
    nextWaterTime = (widget.plantData['nextWaterTime'] as Timestamp).toDate();
    waterIntervalDays = widget.plantData['waterIntervalDays'] ?? 1;
    sunExposureHours = widget.plantData['sunExposureHours'] ?? 4;
    sunStartTime = DateTime.now();

    _startTimer();
    final now = DateTime.now();
    health = now.isAfter(nextWaterTime) ? 'Kötü' : (widget.plantData['health'] ?? 'İyi');
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingWater = nextWaterTime.difference(DateTime.now());
        _remainingSun = sunStartTime.add(Duration(hours: sunExposureHours)).difference(DateTime.now());
      });
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours sa $minutes dk $seconds sn';
  }

  Future<void> updateXP(int xpToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final currentXP = snapshot.data()?['xp'] ?? 0;

    await userRef.update({'xp': currentXP + xpToAdd});
  }

  Future<void> waterPlant() async {
    sunStartTime = DateTime.now();
    await updateXP(10);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bitki Sulandı! +10 XP')),
    );

    await NotificationService.cancelNotification((docId + 'sun').hashCode);
    await NotificationService.scheduleNotification(
      id: (docId + 'sun').hashCode,
      title: 'Bitki Sulama Zamanı!',
      body: '${widget.plantData['name']} yeterince sulandı!',
      scheduledTime: DateTime.now().add(const Duration(hours: 4)),
    );
  }

  Future<void> giveSun() async {
    sunStartTime = DateTime.now();
    await updateXP(10);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Güneşe bırakıldı! +10 XP')),
    );

    await NotificationService.cancelNotification((docId + 'sun').hashCode);
    await NotificationService.scheduleNotification(
      id: (docId + 'sun').hashCode,
      title: 'Güneş Süresi Doldu!',
      body: '${widget.plantData['name']} yeterince güneşlendi!',
      scheduledTime: DateTime.now().add(const Duration(hours: 4)),
    );
  }

  Future<void> showTestNotification() async {
    final now = DateTime.now();
    if (now.hour >= 23 || now.hour < 7) return;

    await NotificationService.showInstantNotification(
      id: 999,
      title: 'Test Bildirimi',
      body: 'Bu bir test bildirimi.',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.plantData['name'];
    final image = widget.plantData['image'];
    final description = widget.plantData['description'];
    final isLate = _remainingWater.isNegative;

    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? 'Bitki Detayı'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset('assets/images/$image', height: 180),
            const SizedBox(height: 16),
            Text(name ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Sağlık Durumu: $health'),
            const SizedBox(height: 8),
            Text(
              isLate
                  ? '❗ Sulama süresi geçti!'
                  : 'Sulama için kalan süre: ${formatDuration(_remainingWater)}',
              style: TextStyle(
                color: isLate ? Colors.red : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Güneşlenme süresi: ${formatDuration(_remainingSun)}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: waterPlant,
              icon: const Icon(Icons.water_drop),
              label: const Text('Suladım'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: giveSun,
              icon: const Icon(Icons.wb_sunny),
              label: const Text('Güneşe Bıraktım'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: showTestNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Bildirimi Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                minimumSize: const Size.fromHeight(50),
              ),
            )
          ],
        ),
      ),
    );
  }
}
