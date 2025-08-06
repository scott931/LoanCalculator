import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _monthlyInterestRateKey = 'monthly_interest_rate';
  static const String _annualInterestRateKey = 'annual_interest_rate';
  static const String _laceFeePercentageKey = 'lace_fee_percentage';
  static const String _insuranceFeePercentageKey = 'insurance_fee_percentage';
  static const String _disbursementFeeKey = 'disbursement_fee';

  // Default values
  static const double _defaultMonthlyInterestRate = 2.60;
  static const double _defaultAnnualInterestRate = 36.09;
  static const double _defaultLaceFeePercentage = 4.0;
  static const double _defaultInsuranceFeePercentage = 1.0;
  static const double _defaultDisbursementFee = 700.0;

  // Get monthly interest rate
  static Future<double> getMonthlyInterestRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlyInterestRateKey) ??
        _defaultMonthlyInterestRate;
  }

  // Get annual interest rate
  static Future<double> getAnnualInterestRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_annualInterestRateKey) ??
        _defaultAnnualInterestRate;
  }

  // Get LACE fee percentage
  static Future<double> getLaceFeePercentage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_laceFeePercentageKey) ?? _defaultLaceFeePercentage;
  }

  // Get insurance fee percentage
  static Future<double> getInsuranceFeePercentage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_insuranceFeePercentageKey) ??
        _defaultInsuranceFeePercentage;
  }

  // Get disbursement fee
  static Future<double> getDisbursementFee() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_disbursementFeeKey) ?? _defaultDisbursementFee;
  }

  // Set monthly interest rate
  static Future<void> setMonthlyInterestRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyInterestRateKey, value);
  }

  // Set annual interest rate
  static Future<void> setAnnualInterestRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_annualInterestRateKey, value);
  }

  // Set LACE fee percentage
  static Future<void> setLaceFeePercentage(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_laceFeePercentageKey, value);
  }

  // Set insurance fee percentage
  static Future<void> setInsuranceFeePercentage(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_insuranceFeePercentageKey, value);
  }

  // Set disbursement fee
  static Future<void> setDisbursementFee(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_disbursementFeeKey, value);
  }

  // Reset all settings to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyInterestRateKey, _defaultMonthlyInterestRate);
    await prefs.setDouble(_annualInterestRateKey, _defaultAnnualInterestRate);
    await prefs.setDouble(_laceFeePercentageKey, _defaultLaceFeePercentage);
    await prefs.setDouble(
        _insuranceFeePercentageKey, _defaultInsuranceFeePercentage);
    await prefs.setDouble(_disbursementFeeKey, _defaultDisbursementFee);
  }

  // Get all settings as a map
  static Future<Map<String, double>> getAllSettings() async {
    return {
      'monthlyInterestRate': await getMonthlyInterestRate(),
      'annualInterestRate': await getAnnualInterestRate(),
      'laceFeePercentage': await getLaceFeePercentage(),
      'insuranceFeePercentage': await getInsuranceFeePercentage(),
      'disbursementFee': await getDisbursementFee(),
    };
  }
}
