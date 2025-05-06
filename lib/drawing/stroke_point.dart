import 'dart:ui';
import 'package:flutter/material.dart';

class StrokePoint {
  final Offset? offset;
  final Color color;
  final double strokeWidth;
  final int t;

  StrokePoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
    required this.t
  });

  Map<String, dynamic> toJson() => {
    "x": offset?.dx,
    "y": offset?.dy,
    "t": t,
  };
}