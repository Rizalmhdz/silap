import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:silap/firebase_options.dart';
import 'package:silap/home_page.dart';


Future<void> main()  async {
  // WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await Alarm.init();
  // tz.initializeTimeZones();
  runApp(const MyApp());
  runApp(const MyApp());
  // await Firebase.initializeApp(); // Pastikan konfigurasi firebase sudah di-
  // await NotificationService.init(); // inisialisasi notifikasi
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SILAP',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}