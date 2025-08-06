import 'package:flutter/material.dart';
import 'screens/calculator_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const LoanCalculatorApp());
}

class LoanCalculatorApp extends StatelessWidget {
  const LoanCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CalculatorScreen(),
    );
  }
}
