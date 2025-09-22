import 'dart:async';
import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:silap/screens/edit_alarm.dart';
import 'package:url_launcher/url_launcher.dart';

class ExampleAlarmRingScreen extends StatefulWidget {
  const ExampleAlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<ExampleAlarmRingScreen> createState() => _ExampleAlarmRingScreenState();
}

class _ExampleAlarmRingScreenState extends State<ExampleAlarmRingScreen> {
  static final _log = Logger('ExampleAlarmRingScreenState');

  StreamSubscription<AlarmSet>? _ringingSubscription;

  @override
  void initState() {
    super.initState();
    _ringingSubscription = Alarm.ringing.listen((alarms) {
      if (alarms.containsId(widget.alarmSettings.id)) return;
      _log.info('Alarm ${widget.alarmSettings.id} stopped ringing.');
      _ringingSubscription?.cancel();
      if (mounted) Navigator.pop(context);
    });
  }

  void _launchLink(String link) async {
    final url = Uri.tryParse(link);
    try {
      if (url != null &&
          await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _log.info('Opening link: $link');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka tautan')));
    }
  }

  int _daysInMonth(int year, int month) {
    return DateTime(
      year,
      month + 1,
      0,
    ).day; // Mengambil jumlah hari di bulan tertentu
  }

  // Function to calculate next occurrence for repeat types
  DateTime nextOccurrence(DateTime from, RepeatType type) {
    switch (type) {
      case RepeatType.daily:
        return from.add(const Duration(days: 1));
      case RepeatType.weekly:
        return from.add(const Duration(days: 7));
      case RepeatType.monthly:
      case RepeatType.monthly:
        final nextMonth = from.month == 12 ? 1 : from.month + 1;
        final year = from.month == 12 ? from.year + 1 : from.year;
        final lastDayOfNextMonth = _daysInMonth(year, nextMonth);
        final day =
            from.day <= lastDayOfNextMonth ? from.day : lastDayOfNextMonth;
        return DateTime(year, nextMonth, day, from.hour, from.minute);
      case RepeatType.none:
      default:
        return from;
    }
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.alarmSettings.notificationSettings?.title ?? 'Alarm';
    final time = TimeOfDay.fromDateTime(
      widget.alarmSettings.dateTime,
    ).format(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$label',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight:
                          FontWeight.bold, // Menambahkan fontWeight bold
                    ),
                    textAlign: TextAlign.center,
                  ),

                  Text(
                    '${jsonDecode(widget.alarmSettings.payload.toString())['deskripsi']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const Text('🔔', style: TextStyle(fontSize: 50)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  RawMaterialButton(
                    onPressed: () async {
                      // Tunda 5 menit
                      await Alarm.set(
                        alarmSettings: widget.alarmSettings.copyWith(
                          dateTime: DateTime.now().add(
                            const Duration(minutes: 5),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Tunda 5 Menit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  RawMaterialButton(
                    onPressed: () async {
                      final payloadString =
                          widget
                              .alarmSettings
                              .payload; // Ambil payload (sekarang berupa String)

                      if (payloadString != null) {
                        // Mengubah String JSON kembali menjadi Map
                        final payload = jsonDecode(payloadString);

                        // Mengambil link dan repeatType dari payload
                        final link = payload['link'];
                        final repeatTypeString = payload['repeatType'];

                        // Parsing repeatType string menjadi enum
                        RepeatType repeatType = RepeatType.none;
                        if (repeatTypeString != null) {
                          repeatType = RepeatType.values.firstWhere(
                            (e) => e.toString() == repeatTypeString,
                            orElse: () => RepeatType.none,
                          );
                        }

                        // Tampilkan link atau lakukan tindakan yang sesuai dengan repeatType
                        if (link != null) {
                          // Stop alarm
                          await Alarm.stop(widget.alarmSettings.id);
                          _launchLink(link); // Jika ada link, buka
                        }

                        // Gunakan repeatType untuk mengatur ulang alarm berdasarkan repeat type
                        if (repeatType != RepeatType.none) {
                          DateTime nextTime = nextOccurrence(
                            widget.alarmSettings.dateTime,
                            repeatType,
                          );

                          await Alarm.set(
                            alarmSettings: widget.alarmSettings.copyWith(
                              id:
                                  DateTime.now().millisecondsSinceEpoch %
                                      10000 +
                                  1,
                              dateTime: nextTime,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Stop dan Buka',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
