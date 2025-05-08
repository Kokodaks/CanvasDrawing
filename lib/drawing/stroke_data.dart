import 'dart:ui';
import 'package:flutter/material.dart';
import 'stroke_point.dart';

class StrokeData {
  final bool isErasing;
  final int strokeOrder;
  final int strokeStartTime;
  final List<StrokePoint> points;
  final Color color;

  StrokeData({
    required this.isErasing,
    required this.strokeOrder,
    required this.strokeStartTime,
    required this.points,
    required this.color
  }) {
    if (points.isEmpty) {
      throw ArgumentError("points list cannot be empty");
    }
  }

  Map<String, dynamic> toJson() => {
    "isErasing": isErasing,
    "strokeOrder": strokeOrder,
    "strokeStartTime": strokeStartTime,
    "color": color.value.toRadixString(16),
    "points": points.map((p) => p.toJson()).toList(),
  };
}
