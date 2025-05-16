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
    "strokeOrder": strokeOrder,
    "strokeStartTime": strokeStartTime,
    "isErasing": isErasing,
    "color": color.value.toRadixString(16),
    "points": points.map((p) => p.toJson()).toList(),
  };

  Map<String, dynamic> toJsonOpenAi() =>{
    "strokeOrder": strokeOrder,
    "strokeStartTime": strokeStartTime,
    "isErasing": isErasing,
    "color": color.value.toRadixString(16),
    "points": _samplePoints(points, 10).map((p)=>{
      "x":p.offset?.dx,
      "y":p.offset?.dy
    }).toList(),
  };

  List<StrokePoint> _samplePoints(List<StrokePoint> points, int interval){
    return List.generate(
        (points.length / interval).ceil(),
        (i) => points[i * interval],
    )..add(points.last);
  }

}