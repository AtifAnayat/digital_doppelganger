// lib/models.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyData {
  final String date;
  final String wakeUpTime;
  final String sleepTime;
  final int screenTimeHours;
  final String mood;

  DailyData({
    required this.date,
    required this.wakeUpTime,
    required this.sleepTime,
    required this.screenTimeHours,
    required this.mood,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'wakeUpTime': wakeUpTime,
      'sleepTime': sleepTime,
      'screenTimeHours': screenTimeHours,
      'mood': mood,
    };
  }

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      date: json['date'],
      wakeUpTime: json['wakeUpTime'],
      sleepTime: json['sleepTime'],
      screenTimeHours: json['screenTimeHours'],
      mood: json['mood'],
    );
  }
}

class DataManager {
  static const String DATA_KEY = 'daily_data_entries';

  static Future<void> saveDailyData(DailyData data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> existingData = prefs.getStringList(DATA_KEY) ?? [];

    existingData.removeWhere((item) {
      Map<String, dynamic> itemData = json.decode(item);
      return itemData['date'] == data.date;
    });

    existingData.add(json.encode(data.toJson()));
    await prefs.setStringList(DATA_KEY, existingData);
  }

  static Future<List<DailyData>> getAllData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dataStrings = prefs.getStringList(DATA_KEY) ?? [];

    return dataStrings.map((dataString) {
      Map<String, dynamic> dataMap = json.decode(dataString);
      return DailyData.fromJson(dataMap);
    }).toList();
  }

  static Future<DailyData?> getDataForDate(String date) async {
    List<DailyData> allData = await getAllData();
    try {
      return allData.firstWhere((data) => data.date == date);
    } catch (e) {
      return null;
    }
  }
}
