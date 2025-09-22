import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:silap/screens/edit_alarm.dart';
import 'package:silap/screens/list_alarm.dart';
import 'package:silap/screens/others_page.dart';
import 'package:silap/screens/ring.dart';
import 'package:silap/services/notifications.dart';
import 'package:silap/services/permission.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const version = '5.1.4';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AlarmSettings> alarms = [];
  Notifications? notifications;

  static StreamSubscription<AlarmSet>? ringSubscription;
  static StreamSubscription<AlarmSet>? updateSubscription;

  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> laporanItems = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchMenuItems();

    AlarmPermissions.checkNotificationPermission().then(
      (_) => AlarmPermissions.checkAndroidScheduleExactAlarmPermission(),
    );
    unawaited(loadAlarms());
    ringSubscription ??= Alarm.ringing.listen(ringingAlarmsChanged);
    updateSubscription ??= Alarm.scheduled.listen((_) {
      unawaited(loadAlarms());
    });
    notifications = Notifications();
  }

  Future<void> loadAlarms() async {
    final updatedAlarms = await Alarm.getAlarms();
    updatedAlarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    setState(() {
      alarms = updatedAlarms;
    });
  }

  Future<void> ringingAlarmsChanged(AlarmSet alarms) async {
    if (alarms.alarms.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (context) =>
                ExampleAlarmRingScreen(alarmSettings: alarms.alarms.first),
      ),
    );
    unawaited(loadAlarms());
  }

  Future<void> navigateToAlarmScreen(
    AlarmSettings? settings, {
    String? namaLaporan,
    String? link,
    String? deskripsi,
  }) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: ExampleAlarmEditScreen(
            alarmSettings: settings,
            namaLaporan: namaLaporan,
            link: link,
            deskripsi: deskripsi,
          ),
        );
      },
    );

    if (res != null && res == true) unawaited(loadAlarms());
  }

  Future<void> launchReadmeUrl() async {
    final url = Uri.parse('https://pub.dev/packages/alarm/versions/$version');
    await launchUrl(url);
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _launchLink(String link) async {
    final url = Uri.tryParse(link);
    try {
      await launchUrl(url!, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka tautan')));
    }
  }

  @override
  void dispose() {
    ringSubscription?.cancel();
    updateSubscription?.cancel();
    super.dispose();
  }

  void _fetchMenuItems() async {
    try {
      final snapshot = await ref.child('laporan').get();
      if (snapshot.exists) {
        final List<Map<String, dynamic>> tempList = [];
        for (final item in snapshot.children) {
          final val = item.value as Map;
          tempList.add({
            'nama': val['nama'] ?? '',
            'link': val['link'] ?? '',
            'deskripsi': val['deskripsi'] ?? '',
            'passcode': val['passcode'] ?? '',
            'admin': val['admin'] ?? '',
          });
        }
        setState(() {
          laporanItems = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ketika back button ditekan, langsung keluar dari aplikasi
        return true; // Mengindikasikan aplikasi harus keluar
      },
      child: Scaffold(
        backgroundColor: Color(0xFF5E665D),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo1.png', height: 60),
                      const SizedBox(width: 10),
                      Text(
                        'SILAP',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'SISTEM INTEGRASI PELAPORAN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SatPol PP & Damkar PemProv Kalsel\nBidang TibumTranmas Seksi OPDAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (isLoading)
                CircularProgressIndicator(color: Colors.white)
              else
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [
                      // Halaman 1 - fullwidth
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        // full lebar tanpa margin kiri/kanan
                        itemCount: laporanItems.length,
                        itemBuilder: (context, index) {
                          final item = laporanItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 15.0,
                              left: 15.0,
                              right: 15.0,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFB3A78A),
                                foregroundColor: Colors.white,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                minimumSize: Size(double.infinity, 45),
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  builder:
                                      (_) => Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Align(
                                              child: Text(
                                                item['nama'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              item['deskripsi'],
                                              style: TextStyle(
                                                color: Colors.black45,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Pengelola: ${item['admin']}',
                                              style: TextStyle(
                                                color: Colors.black45,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // Text('passcode: ${item['passcode']}', style: TextStyle(color: Colors.black45)),
                                            // const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                // tambah pengingat
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.alarm_add,
                                                    color: Colors.brown,
                                                  ),
                                                  onPressed:
                                                      () => navigateToAlarmScreen(
                                                        null,
                                                        namaLaporan:
                                                            item['nama'],
                                                        link: item['link'],
                                                        deskripsi:
                                                            item['deskripsi'],
                                                      ),
                                                ),
                                                ElevatedButton.icon(
                                                  icon: Icon(
                                                    Icons.open_in_new,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text('Buka'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.brown[400],
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () {
                                                    final passcode =
                                                        item['passcode'] ?? '';
                                                    final link =
                                                        item['link'] ?? '';

                                                    if (passcode.isEmpty) {
                                                      // Jika tidak ada passcode, langsung buka link
                                                      _launchLink(link);
                                                    } else {
                                                      // Jika ada passcode, tampilkan dialog input
                                                      String inputCode = '';
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => AlertDialog(
                                                              title: Text(
                                                                'Masukkan Passcode',
                                                              ),
                                                              content: TextField(
                                                                obscureText:
                                                                    true,
                                                                autofocus: true,
                                                                decoration:
                                                                    InputDecoration(
                                                                      hintText:
                                                                          'Passcode',
                                                                    ),
                                                                onChanged:
                                                                    (value) =>
                                                                        inputCode =
                                                                            value,
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  child: Text(
                                                                    'Batal',
                                                                  ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                      ),
                                                                ),
                                                                ElevatedButton(
                                                                  child: Text(
                                                                    'Lanjut',
                                                                  ),
                                                                  onPressed: () {
                                                                    if (inputCode ==
                                                                        passcode) {
                                                                      Navigator.pop(
                                                                        context,
                                                                      );
                                                                      _launchLink(
                                                                        link,
                                                                      );
                                                                    } else {
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            'Passcode salah',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                              child: Text(item['nama']),
                            ),
                          );
                        },
                      ),
                      // Halaman 2
                      ListAlarmsPage(),
                      // Halaman 3
                      LainnyaPage(),
                    ],
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.brown[400],
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Laporan'),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Pengingat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Lainnya',
            ),
          ],
        ),
      ),
    );
  }
}
