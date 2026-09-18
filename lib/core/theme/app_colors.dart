import 'package:flutter/material.dart';

class AppColors {
  // Paleta Apple/iOS & MyFitnessPal Inspiration
  static const Color lakeBlue = Color(0xFF0072CE);
  static const Color mfpBlue = Color(0xFF005DAA);
  static const Color skyBlue = Color(0xFFE7F0FF);
  static const Color skyBlueDark = Color(0xFFCCE0FF);

  // Cores de Saúde Biológica & Estado Térmico
  static const Color healthIdeal = Color(0xFF19C37D); // 26°C a 32°C
  static const Color healthWarning = Color(0xFFF59E0B); // <26°C ou >32°C
  static const Color healthCritical = Color(0xFFEF4444); // <22°C ou >35°C

  // Conexão ESP32
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color offlineRed = Color(0xFFEF4444);
  static const Color connectingAmber = Color(0xFFF59E0B);

  // Tons de mel e abelha
  static const Color honeyGold = Color(0xFFF59E0B);
  static const Color honeyAmber = Color(0xFFD97706);
  static const Color pollenYellow = Color(0xFFFBBF24);
  static const Color beeswax = Color(0xFFFFD66B);
  static const Color nectar = Color(0xFFFFB703);
  static const Color propolis = Color(0xFF714B25);
  static const Color hiveBrown = Color(0xFF3B2A1E);
  static const Color forest = Color(0xFF254A3B);
  static const Color leaf = Color(0xFF6E9C5B);

  // Superfícies e Vidro (Glassmorphism)
  static const Color canvasBg = Color(0xFFFFF7E8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF1F5F9);
  static const Color surfaceGlass = Color(0xCCFFFFFF); // 80% opacity
  static const Color glassBorder = Color(0x66FFFFFF);

  // Tipografia iOS
  static const Color ink = Color(0xFF1F2937); // Texto Primário
  static const Color slate = Color(0xFF4B5563); // Secundário
  static const Color mute = Color(0xFF9CA3AF); // Terciário / Desabilitado
  static const Color heroNumber = Color(0xFF111827); // Números destacados

  // Linhas e Divisores
  static const Color divider = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFE2E8F0);
}
