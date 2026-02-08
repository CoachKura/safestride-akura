// lib/theme/dashboard_colors.dart
import 'package:flutter/material.dart';

class DashboardColors {
  // Circular progress gradients
  static const stepsGradient = [
    Color(0xFF667EEA),
    Color(0xFF764BA2)
  ]; // Blue-Purple
  static const distanceGradient = [
    Color(0xFFF79D00),
    Color(0xFF64F38C)
  ]; // Orange-Green
  static const caloriesGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D)
  ]; // Red-Yellow
  static const sleepGradient = [
    Color(0xFFF79D00),
    Color(0xFF667EEA)
  ]; // Orange-Blue
  static const heartRateGradient = [
    Color(0xFFFF6B9D),
    Color(0xFFC837AB)
  ]; // Pink-Purple

  // Chart colors
  static const activityChartGradient = [Color(0xFFF79D00), Color(0xFFFFD93D)];
  static const heartRateChart = Color(0xFFFF6B9D);
  static const paceChart = Color(0xFF667EEA);

  // Stat card icon colors
  static const activeCaloriesColor = Color(0xFF667EEA); // Blue
  static const activitiesColor = Color(0xFFF79D00); // Orange
  static const remainingColor = Color(0xFFFF6B6B); // Red
  static const consumedColor = Color(0xFF64F38C); // Green

  // Background colors
  static const cardBackground = Color(0xFF1E1E1E);
  static const screenBackground = Color(0xFF000000);
  static const borderColor = Color(0xFF2E2E2E);

  // Text colors
  static const primaryText = Colors.white;
  static const secondaryText = Color(0xFF9E9E9E);

  // Get gradient for metric type
  static List<Color> getGradient(String type) {
    switch (type.toLowerCase()) {
      case 'steps':
        return stepsGradient;
      case 'distance':
        return distanceGradient;
      case 'calories':
        return caloriesGradient;
      case 'sleep':
        return sleepGradient;
      case 'heartrate':
      case 'heart_rate':
        return heartRateGradient;
      default:
        return stepsGradient;
    }
  }
}
