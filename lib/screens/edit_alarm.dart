import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

enum RepeatType { none, daily, weekly, monthly }

class ExampleAlarmEditScreen extends StatefulWidget {
  final AlarmSettings? alarmSettings;
  final String? namaLaporan;
  final String? link;
  final String? deskripsi;

  const ExampleAlarmEditScreen({
    Key? key,
    this.alarmSettings,
    this.namaLaporan,
    this.link,
    this.deskripsi,
  }) : super(key: key);

  @override
  State<ExampleAlarmEditScreen> createState() => _ExampleAlarmEditScreenState();
}

class _ExampleAlarmEditScreenState extends State<ExampleAlarmEditScreen> {
  bool creating = true;
  bool loading = false;

  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late String assetAudio;
  late double volume;
  Duration? fadeDuration;
  bool staircaseFade = false;

  RepeatType repeatType = RepeatType.none;

  @override
  void initState() {
    super.initState();
    creating = widget.alarmSettings == null;

    if (creating) {
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      loopAudio = true;
      vibrate = true;
      assetAudio = 'assets/marimba.mp3';
      volume = 1.0;
    } else {
      volume = widget.alarmSettings!.volumeSettings.volume!;
      selectedDateTime = widget.alarmSettings!.dateTime;
      loopAudio = widget.alarmSettings!.loopAudio;
      vibrate = widget.alarmSettings!.vibrate;
      assetAudio = widget.alarmSettings!.assetAudioPath;
    }
  }

  AlarmSettings buildAlarmSettings() {
    final id =
        creating
            ? DateTime.now().millisecondsSinceEpoch % 10000 + 1
            : widget.alarmSettings!.id;

    final VolumeSettings volumeSettings;
    if (staircaseFade) {
      volumeSettings = VolumeSettings.staircaseFade(
        volume: volume,
        fadeSteps: [
          VolumeFadeStep(Duration.zero, 0),
          VolumeFadeStep(const Duration(seconds: 15), 0.03),
          VolumeFadeStep(const Duration(seconds: 20), 0.5),
          VolumeFadeStep(const Duration(seconds: 30), 1),
        ],
      );
    } else if (fadeDuration != null) {
      volumeSettings = VolumeSettings.fade(
        volume: volume,
        fadeDuration: fadeDuration!,
      );
    } else {
      volumeSettings = VolumeSettings.fixed(volume: volume);
    }

    // Menyimpan link dan repeatType ke dalam payload
    final payload = jsonEncode({
      'link': widget.link, // Menyimpan link
      'deskripsi': widget.deskripsi,
      'repeatType': repeatType.toString(), // Menyimpan repeat type
    });

    return AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      assetAudioPath: assetAudio,
      volumeSettings: volumeSettings,
      allowAlarmOverlap: true,
      notificationSettings: NotificationSettings(
        title: '${widget.namaLaporan ?? ""}',
        body: 'Pengingat untuk laporan ${widget.namaLaporan ?? ''}',
        // stopButton: 'Stop alarm',
        icon: 'notification_icon',
      ),
      payload: payload,
    );
  }

  Future<void> saveAlarm() async {
    if (loading) return;
    setState(() => loading = true);

    final alarm = buildAlarmSettings();
    final res = await Alarm.set(alarmSettings: alarm);

    if (res) {
      if (mounted) Navigator.pop(context, true);
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(creating ? "Buat Alarm" : "Edit Alarm"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveAlarm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Waktu Pengingat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Waktu", style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date == null) return;

                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time == null) return;

                    setState(() {
                      selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  child: Text(
                    "${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} "
                    "${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}",
                  ),
                ),
              ],
            ),
            const Divider(),

            // Repeat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<RepeatType>(
                  value: repeatType,
                  items: const [
                    DropdownMenuItem(
                      value: RepeatType.none,
                      child: Text('Sekali'),
                    ),
                    DropdownMenuItem(
                      value: RepeatType.daily,
                      child: Text('Harian'),
                    ),
                    DropdownMenuItem(
                      value: RepeatType.weekly,
                      child: Text('Mingguan'),
                    ),
                    DropdownMenuItem(
                      value: RepeatType.monthly,
                      child: Text('Bulanan'),
                    ),
                  ],
                  onChanged: (val) => setState(() => repeatType = val!),
                ),
              ],
            ),
            const Divider(),

            // Getar
            SwitchListTile(
              title: const Text("Vibrate"),
              value: vibrate,
              onChanged: (v) => setState(() => vibrate = v),
            ),

            // Loop Audio
            SwitchListTile(
              title: const Text("Loop Audio"),
              value: loopAudio,
              onChanged: (v) => setState(() => loopAudio = v),
            ),

            // Volume
            ListTile(
              title: const Text("Volume"),
              subtitle: Slider(
                value: volume,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: (v) => setState(() => volume = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
