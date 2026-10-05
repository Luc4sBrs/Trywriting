import 'package:flutter/material.dart';

class TaskLabelHelper {
  static const Map<String, Color> labels = {
    'Urgente': Colors.red,
    'Bug': Colors.orange,
    'Feature': Colors.blue,
    'Design': Colors.purple,
    'Melhoria': Colors.green,
  };

  static Color getColor(String? labelName) {
    if (labelName == null) return Colors.grey;
    return labels[labelName] ?? Colors.teal;
  }
}