// =================================================================================
// 2. ARQUIVO: lib/app_colors.dart (CORRIGIDO PARA TEMA ESCURO)
// =================================================================================
import 'package:flutter/material.dart';

class AppColors {
  // Mude de 'Color' para 'MaterialColor'
  static const MaterialColor primary = Colors.deepPurple; // <--- CORREÇÃO AQUI
  static const Color accent = Colors.amber;
  static const Color price = Color(0xFF2E7D32);
  static const Color danger = Colors.red;
}