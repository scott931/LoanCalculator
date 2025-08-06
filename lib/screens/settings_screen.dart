import 'package:flutter/material.dart';
import '../utils/settings_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyInterestController = TextEditingController();
  final _annualInterestController = TextEditingController();
  final _laceFeeController = TextEditingController();
  final _insuranceFeeController = TextEditingController();
  final _disbursementFeeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _monthlyInterestController.dispose();
    _annualInterestController.dispose();
    _laceFeeController.dispose();
    _insuranceFeeController.dispose();
    _disbursementFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.getAllSettings();

      setState(() {
        _monthlyInterestController.text =
            settings['monthlyInterestRate']!.toStringAsFixed(2);
        _annualInterestController.text =
            settings['annualInterestRate']!.toStringAsFixed(2);
        _laceFeeController.text =
            settings['laceFeePercentage']!.toStringAsFixed(2);
        _insuranceFeeController.text =
            settings['insuranceFeePercentage']!.toStringAsFixed(2);
        _disbursementFeeController.text =
            settings['disbursementFee']!.toStringAsFixed(2);
        _isLoading = false;
      });
    } catch (e) {
      // Use default values if loading fails
      setState(() {
        _monthlyInterestController.text = '2.60';
        _annualInterestController.text = '36.09';
        _laceFeeController.text = '4.0';
        _insuranceFeeController.text = '1.0';
        _disbursementFeeController.text = '700.0';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await SettingsService.setMonthlyInterestRate(
          double.parse(_monthlyInterestController.text));
      await SettingsService.setAnnualInterestRate(
          double.parse(_annualInterestController.text));
      await SettingsService.setLaceFeePercentage(
          double.parse(_laceFeeController.text));
      await SettingsService.setInsuranceFeePercentage(
          double.parse(_insuranceFeeController.text));
      await SettingsService.setDisbursementFee(
          double.parse(_disbursementFeeController.text));

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    await SettingsService.resetToDefaults();
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _resetToDefaults,
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interest Rates Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.percent,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Interest Rates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Monthly Interest Rate
                    _buildInputField(
                      controller: _monthlyInterestController,
                      label: 'Monthly Interest Rate (%)',
                      hint: 'Enter monthly interest rate',
                      suffix: '%',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter monthly interest rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        final rate = double.parse(value);
                        if (rate < 0 || rate > 100) {
                          return 'Rate must be between 0 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Annual Interest Rate
                    _buildInputField(
                      controller: _annualInterestController,
                      label: 'Annual Interest Rate (%)',
                      hint: 'Enter annual interest rate',
                      suffix: '%',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter annual interest rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        final rate = double.parse(value);
                        if (rate < 0 || rate > 100) {
                          return 'Rate must be between 0 and 100';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Fees Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loan Fees',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LACE Fee
                    _buildInputField(
                      controller: _laceFeeController,
                      label: 'LACE Fee (% of loan amount)',
                      hint: 'Enter LACE fee percentage',
                      suffix: '%',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter LACE fee';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        final fee = double.parse(value);
                        if (fee < 0 || fee > 100) {
                          return 'Fee must be between 0 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Insurance Fee
                    _buildInputField(
                      controller: _insuranceFeeController,
                      label: 'Insurance Fee (% per annum)',
                      hint: 'Enter insurance fee percentage',
                      suffix: '%',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter insurance fee';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        final fee = double.parse(value);
                        if (fee < 0 || fee > 100) {
                          return 'Fee must be between 0 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Disbursement Fee
                    _buildInputField(
                      controller: _disbursementFeeController,
                      label: 'Disbursement Fee (\$)',
                      hint: 'Enter disbursement fee amount',
                      prefix: '\$',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter disbursement fee';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        final fee = double.parse(value);
                        if (fee < 0) {
                          return 'Fee must be 0 or greater';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    String? suffix,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
        ),
      ],
    );
  }
}
