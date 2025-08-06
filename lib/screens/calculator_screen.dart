import 'dart:math';
import 'package:flutter/material.dart';
import '../models/loan_calculation.dart';
import '../utils/loan_formulas.dart';
import '../utils/excel_export.dart';
import '../utils/formatters.dart';
import '../widgets/input_field.dart';
import '../widgets/calculate_button.dart';
import '../widgets/result_card.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/fee_breakdown_card.dart';
import 'settings_screen.dart';
import 'saved_calculations_screen.dart';
import '../utils/app_theme.dart';
import '../models/saved_calculation.dart';
import '../services/saved_calculations_service.dart';

enum LoanType { home, personal, car }

class CalculatorScreen extends StatefulWidget {
  final SavedCalculation? savedCalculation;

  const CalculatorScreen({super.key, this.savedCalculation});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanAmountController = TextEditingController(text: '5000000');
  final _loanTermController = TextEditingController(text: '10');
  final _interestRateController = TextEditingController(text: '9.5');
  final _monthlyPaymentController = TextEditingController();
  final _earlyPaymentController = TextEditingController();

  DateTime _selectedLoanDate = DateTime.now();
  DateTime _selectedSettlementDate = DateTime.now();
  LoanCalculation? _calculation;
  bool _isCalculating = false;
  LoanType _selectedLoanType = LoanType.home;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalculation != null) {
      _loadSavedCalculation(widget.savedCalculation!);
    }
  }

  void _loadSavedCalculation(SavedCalculation savedCalculation) {
    final inputData = savedCalculation.inputData;

    _loanAmountController.text = inputData['loanAmount']?.toString() ?? '';
    _loanTermController.text = inputData['loanTerm']?.toString() ?? '';
    _monthlyPaymentController.text =
        inputData['monthlyPayment']?.toString() ?? '';
    _selectedLoanDate = DateTime.fromMillisecondsSinceEpoch(
        inputData['loanDate'] ?? DateTime.now().millisecondsSinceEpoch);
    _selectedSettlementDate = DateTime.fromMillisecondsSinceEpoch(
        inputData['settlementDate'] ?? DateTime.now().millisecondsSinceEpoch);

    setState(() {
      _calculation = savedCalculation.calculation;
    });
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _loanTermController.dispose();
    _interestRateController.dispose();
    _monthlyPaymentController.dispose();
    _earlyPaymentController.dispose();
    super.dispose();
  }

  void _calculateEMI() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final principal = double.parse(_loanAmountController.text);
      final loanTerm = int.parse(_loanTermController.text);
      final interestRate = double.parse(_interestRateController.text);

      // Calculate monthly interest rate
      final monthlyInterestRate = interestRate / 100 / 12;
      final numberOfPayments = loanTerm * 12;

      // EMI formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
      final emi = principal *
          monthlyInterestRate *
          pow(1 + monthlyInterestRate, numberOfPayments) /
          (pow(1 + monthlyInterestRate, numberOfPayments) - 1);

      final totalPayment = emi * numberOfPayments;
      final totalInterest = totalPayment - principal;

      final calculation = LoanCalculation(
        principal: principal,
        annualInterestRate: interestRate,
        monthlyInterestRate: monthlyInterestRate,
        loanTerm: loanTerm,
        monthlyPayment: emi,
        totalPayment: totalPayment,
        totalInterest: totalInterest,
        laceFee: 0,
        insuranceFee: 0,
        disbursementFee: 0,
        totalFees: 0,
        paymentSchedule: [],
        loanDate: _selectedLoanDate,
      );

      setState(() {
        _calculation = calculation;
        _isCalculating = false;
        _showResults = true;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating EMI: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCalculation() async {
    if (_calculation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate EMI first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SaveCalculationDialog(),
    );

    if (result != null) {
      try {
        final savedCalculation = SavedCalculation(
          id: SavedCalculationsService.generateId(),
          name: result['name'],
          savedAt: DateTime.now(),
          calculation: _calculation!,
          inputData: {
            'loanAmount': double.parse(_loanAmountController.text),
            'loanTerm': int.parse(_loanTermController.text),
            'interestRate': double.parse(_interestRateController.text),
            'loanDate': _selectedLoanDate.millisecondsSinceEpoch,
            'settlementDate': _selectedSettlementDate.millisecondsSinceEpoch,
          },
        );

        await SavedCalculationsService.saveCalculation(savedCalculation);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calculation saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving calculation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportToExcel() async {
    if (_calculation == null) return;

    try {
      await ExcelExport.exportToExcel(
        _calculation!,
        paymentsMade: null,
        settlementDate: _selectedSettlementDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan schedule exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting to Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportToCSV() async {
    if (_calculation == null) return;

    try {
      await ExcelExport.exportToCSV(
        _calculation!,
        paymentsMade: null,
        settlementDate: _selectedSettlementDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan schedule exported to CSV successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting to CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bank of Los Santos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Show menu options
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'EMI Calculator',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Loan Type Section
              Text(
                'Loan Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLoanTypeButton(
                      type: LoanType.home,
                      icon: Icons.home,
                      label: 'Home',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLoanTypeButton(
                      type: LoanType.personal,
                      icon: Icons.person,
                      label: 'Personal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLoanTypeButton(
                      type: LoanType.car,
                      icon: Icons.directions_car,
                      label: 'Car',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Input Fields Section
              _buildInputField(
                label: '${_getLoanTypeLabel()} Loan Amount',
                controller: _loanAmountController,
                prefix: '₹',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter loan amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Loan amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInputField(
                      label: 'Loan Tenure',
                      controller: _loanTermController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter loan tenure';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Loan tenure must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTenureTypeButtons(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInputField(
                      label: 'Interest Rate',
                      controller: _interestRateController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter interest rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Interest rate must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Calculate EMI Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCalculating ? null : _calculateEMI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCalculating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Calculate EMI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              if (_showResults && _calculation != null) ...[
                const SizedBox(height: 40),
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanTypeButton({
    required LoanType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedLoanType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLoanType = type;
        });
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTenureTypeButtons() {
    return Column(
      children: [
        const SizedBox(height: 32), // Align with input field
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    'Yr',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    'Mo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return Column(
      children: [
        // EMI Circle
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 8),
          ),
          child: Stack(
            children: [
              // Progress circle
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: 0.75, // 75% progress
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor),
                ),
              ),
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your EMI is',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatNumber(_calculation!.monthlyPayment)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'per Month',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Summary Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                label: 'Principal Amount',
                value: '₹${_formatNumber(_calculation!.principal)}',
                showDot: false,
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Total Interest',
                value: '₹${_formatNumber(_calculation!.totalInterest)}',
                showDot: true,
                dotColor: AppTheme.secondaryColor,
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                label: 'Total Payment',
                value: '₹${_formatNumber(_calculation!.totalPayment)}',
                showDot: true,
                dotColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Amortization Details
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Amortization Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Payments starting from ${_formatDate(_selectedLoanDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildAmortizationYear('2023'),
              _buildAmortizationYear('2024'),
              _buildAmortizationYear('2025'),
              _buildAmortizationYear('2026'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool showDot,
    Color? dotColor,
  }) {
    return Row(
      children: [
        if (showDot) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmortizationYear(String year) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              year,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
        if (year != '2026') const Divider(height: 16),
      ],
    );
  }

  String _getLoanTypeLabel() {
    switch (_selectedLoanType) {
      case LoanType.home:
        return 'Home';
      case LoanType.personal:
        return 'Personal';
      case LoanType.car:
        return 'Car';
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _SaveCalculationDialog extends StatefulWidget {
  @override
  State<_SaveCalculationDialog> createState() => _SaveCalculationDialogState();
}

class _SaveCalculationDialogState extends State<_SaveCalculationDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Calculation'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Calculation Name',
          hintText: 'Enter a name for this calculation',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'name': _nameController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
