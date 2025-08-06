import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_calculation.dart';

class SavedCalculationsService {
  static const String _storageKey = 'saved_calculations';

  // Save a new calculation
  static Future<void> saveCalculation(SavedCalculation calculation) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCalculations = await getAllSavedCalculations();

    // Add new calculation
    savedCalculations.add(calculation);

    // Save to storage
    final jsonList = savedCalculations.map((calc) => calc.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Get all saved calculations
  static Future<List<SavedCalculation>> getAllSavedCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => SavedCalculation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get a specific calculation by ID
  static Future<SavedCalculation?> getCalculationById(String id) async {
    final calculations = await getAllSavedCalculations();
    try {
      return calculations.firstWhere((calc) => calc.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update an existing calculation
  static Future<bool> updateCalculation(
      SavedCalculation updatedCalculation) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCalculations = await getAllSavedCalculations();

    final index = savedCalculations
        .indexWhere((calc) => calc.id == updatedCalculation.id);
    if (index == -1) return false;

    savedCalculations[index] = updatedCalculation;

    final jsonList = savedCalculations.map((calc) => calc.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    return true;
  }

  // Delete a calculation
  static Future<bool> deleteCalculation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCalculations = await getAllSavedCalculations();

    final initialLength = savedCalculations.length;
    savedCalculations.removeWhere((calc) => calc.id == id);

    if (savedCalculations.length == initialLength) return false;

    final jsonList = savedCalculations.map((calc) => calc.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    return true;
  }

  // Clear all saved calculations
  static Future<void> clearAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // Generate a unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
