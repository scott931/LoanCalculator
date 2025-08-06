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

class CalculatorScreen extends StatefulWidget {
  final SavedCalculation? savedCalculation;

  const CalculatorScreen({super.key, this.savedCalculation});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanAmountController = TextEditingController();
  final _loanTermController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  final _earlyPaymentController = TextEditingController();

  DateTime _selectedLoanDate = DateTime.now();
  DateTime _selectedSettlementDate = DateTime.now();
  LoanCalculation? _calculation;
  bool _isCalculating = false;

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
    _monthlyPaymentController.dispose();
    _earlyPaymentController.dispose();
    super.dispose();
  }

  void _calculateLoan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final principal = double.parse(_loanAmountController.text);
      final loanTerm = int.parse(_loanTermController.text);
      final monthlyPayment = double.parse(_monthlyPaymentController.text);

      final calculation = await LoanFormulas.calculateLoan(
        principal: principal,
        loanTerm: loanTerm,
        monthlyPayment: monthlyPayment,
        loanDate: _selectedLoanDate,
      );

      setState(() {
        _calculation = calculation;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating loan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCalculation() async {
    if (_calculation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate a loan first'),
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
            'monthlyPayment': double.parse(_monthlyPaymentController.text),
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
      int? paymentsMade;
      if (_earlyPaymentController.text.isNotEmpty) {
        paymentsMade = int.tryParse(_earlyPaymentController.text);
      }

      await ExcelExport.exportToExcel(
        _calculation!,
        paymentsMade: paymentsMade,
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
      int? paymentsMade;
      if (_earlyPaymentController.text.isNotEmpty) {
        paymentsMade = int.tryParse(_earlyPaymentController.text);
      }

      await ExcelExport.exportToCSV(
        _calculation!,
        paymentsMade: paymentsMade,
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

  double? _calculateEarlySettlement() {
    if (_calculation == null || _earlyPaymentController.text.isEmpty)
      return null;

    try {
      final paymentsMade = int.parse(_earlyPaymentController.text);
      if (paymentsMade < 0 ||
          paymentsMade > _calculation!.paymentSchedule.length) {
        return null;
      }

      return _calculation!
          .calculateSettlementAmount(_selectedSettlementDate, paymentsMade);
    } catch (e) {
      return null;
    }
  }

  double? _calculateTotalAmountPaid() {
    if (_calculation == null || _earlyPaymentController.text.isEmpty)
      return null;

    try {
      final paymentsMade = int.parse(_earlyPaymentController.text);
      if (paymentsMade < 0 ||
          paymentsMade > _calculation!.paymentSchedule.length) {
        return null;
      }

      // Calculate total amount paid so far
      double totalPaid = paymentsMade * _calculation!.monthlyPayment;

      // Add the early settlement amount
      double settlementAmount = _calculateEarlySettlement() ?? 0;

      return totalPaid + settlementAmount;
    } catch (e) {
      return null;
    }
  }

  double? _calculateAmountSaved() {
    if (_calculation == null || _earlyPaymentController.text.isEmpty)
      return null;

    try {
      final paymentsMade = int.parse(_earlyPaymentController.text);
      if (paymentsMade < 0 ||
          paymentsMade > _calculation!.paymentSchedule.length) {
        return null;
      }

      // Calculate what would be paid if continuing the loan
      double remainingPayments =
          (_calculation!.paymentSchedule.length - paymentsMade).toDouble();
      double totalIfContinued =
          remainingPayments * _calculation!.monthlyPayment;

      // Calculate what will be paid with early settlement
      double settlementAmount = _calculateEarlySettlement() ?? 0;

      // Amount saved = what would be paid - what will be paid
      return totalIfContinued - settlementAmount;
    } catch (e) {
      return null;
    }
  }

  double? _calculateWholeAmountInMonth() {
    if (_calculation == null || _earlyPaymentController.text.isEmpty)
      return null;

    try {
      final paymentsMade = int.parse(_earlyPaymentController.text);
      if (paymentsMade < 0 ||
          paymentsMade > _calculation!.paymentSchedule.length) {
        return null;
      }

      // Calculate the total amount needed to pay off the loan completely
      double totalPaidSoFar = paymentsMade * _calculation!.monthlyPayment;
      double totalLoanAmount = _calculation!.totalPayment;

      // Amount needed to pay off completely
      return totalLoanAmount - totalPaidSoFar;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final earlySettlementAmount = _calculateEarlySettlement();
    final totalAmountPaid = _calculateTotalAmountPaid();
    final amountSaved = _calculateAmountSaved();
    final wholeAmountInMonth = _calculateWholeAmountInMonth();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Loan Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Calculation',
            onPressed: _saveCalculation,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Saved Calculations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedCalculationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          if (_calculation != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export',
              onSelected: (value) {
                if (value == 'excel') {
                  _exportToExcel();
                } else if (value == 'csv') {
                  _exportToCSV();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Export to Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Export to CSV'),
                    ],
                  ),
                ),
              ],
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
              // Input Section
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
                    Text(
                      'Loan Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Loan Amount
                    InputField(
                      controller: _loanAmountController,
                      label: 'Loan Amount Applied',
                      hint: 'Enter loan amount',
                      prefix: '\$',
                      keyboardType: TextInputType.number,
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
                    const SizedBox(height: 16),

                    // Loan Term
                    InputField(
                      controller: _loanTermController,
                      label: 'Loan Term (Years)',
                      hint: 'Enter loan term in years',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter loan term';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Loan term must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Loan Date
                    DatePickerField(
                      label: 'Loan Date',
                      initialDate: _selectedLoanDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedLoanDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Monthly Payment
                    InputField(
                      controller: _monthlyPaymentController,
                      label: 'Installment Required',
                      hint: 'Enter monthly payment amount',
                      prefix: '\$',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter monthly payment';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Monthly payment must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: CalculateButton(
                        onPressed: _isCalculating ? () {} : _calculateLoan,
                        isLoading: _isCalculating,
                      ),
                    ),
                  ],
                ),
              ),

              if (_calculation != null) ...[
                const SizedBox(height: 20),

                // Fee Breakdown
                FeeBreakdownCard(
                  laceFee: _calculation!.laceFee,
                  insuranceFee: _calculation!.insuranceFee,
                  disbursementFee: _calculation!.disbursementFee,
                  totalFees: _calculation!.totalFees,
                ),

                const SizedBox(height: 20),

                // Loan Summary
                ResultCard(
                  title: 'Loan Summary',
                  items: [
                    ResultItem(
                      label: 'Principal Amount',
                      value:
                          _calculation!.formatCurrency(_calculation!.principal),
                    ),
                    ResultItem(
                      label: 'Annual Interest Rate',
                      value: '${_calculation!.annualInterestRate}%',
                    ),
                    ResultItem(
                      label: 'Monthly Interest Rate',
                      value: '${_calculation!.monthlyInterestRate * 100}%',
                    ),
                    ResultItem(
                      label: 'Monthly Payment',
                      value: _calculation!
                          .formatCurrency(_calculation!.monthlyPayment),
                    ),
                    ResultItem(
                      label: 'Loan Term',
                      value: '${_calculation!.loanTerm} years',
                    ),
                    ResultItem(
                      label: 'Total Payment',
                      value: _calculation!
                          .formatCurrency(_calculation!.totalPayment),
                    ),
                    ResultItem(
                      label: 'Total Interest',
                      value: _calculation!
                          .formatCurrency(_calculation!.totalInterest),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Total Amount Paid Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Total Amount to Pay',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Principal + Interest + Fees',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _calculation!.formatCurrency(
                                      _calculation!.totalPayment +
                                          _calculation!.totalFees),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Complete Cost',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Breakdown:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Principal: ${_calculation!.formatCurrency(_calculation!.principal)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Interest: ${_calculation!.formatCurrency(_calculation!.totalInterest)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Fees: ${_calculation!.formatCurrency(_calculation!.totalFees)}',
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
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Early Payment Calculator
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
                            Icons.payment,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Early Payment Calculator',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Calculate the exact amount needed to settle your loan early after making a certain number of payments.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payments Made Input
                      InputField(
                        controller: _earlyPaymentController,
                        label: 'Number of Payments Made',
                        hint: 'Enter number of payments made',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // Optional field
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          final payments = int.parse(value);
                          if (payments < 0) {
                            return 'Payments must be 0 or greater';
                          }
                          if (payments > _calculation!.paymentSchedule.length) {
                            return 'Cannot exceed total loan term';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Settlement Date
                      DatePickerField(
                        label: 'Settlement Date',
                        initialDate: _selectedSettlementDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedSettlementDate = date;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Early Settlement Results
                      if (earlySettlementAmount != null) ...[
                        // Early Settlement Amount
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.successColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Early Settlement Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Formatters.formatCurrency(
                                    earlySettlementAmount),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on ${_earlyPaymentController.text} payments made',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.successColor.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Total Amount Paid
                        if (totalAmountPaid != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.infoLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.infoColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: AppTheme.infoColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Amount Paid',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.formatCurrency(totalAmountPaid),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.infoColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Including ${_earlyPaymentController.text} payments + settlement',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.infoColor.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Amount Saved
                        if (amountSaved != null && amountSaved > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.secondaryColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      color: AppTheme.secondaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Amount Saved',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.formatCurrency(amountSaved),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Compared to continuing the loan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondaryColor
                                        .withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Whole Amount in Month
                        if (wholeAmountInMonth != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.accentColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Complete Payoff Amount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.formatCurrency(wholeAmountInMonth),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'To pay off the entire loan in month ${_earlyPaymentController.text}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTheme.accentColor.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else if (_earlyPaymentController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.warningLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.warningColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: AppTheme.warningColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please enter a valid number of payments (0-${_calculation!.paymentSchedule.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.warningColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Schedule Preview
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
                            Icons.schedule,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Schedule (Full Term)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Total Amount Paid Summary
                      if (_earlyPaymentController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.infoColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: AppTheme.infoColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Amount Paid So Far',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatCurrency(
                                        int.parse(
                                                _earlyPaymentController.text) *
                                            _calculation!.monthlyPayment,
                                      ),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                    Text(
                                      '${_earlyPaymentController.text} payments × ${Formatters.formatCurrency(_calculation!.monthlyPayment)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppTheme.infoColor.withOpacity(0.8),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_earlyPaymentController.text} months',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text(
                        'Total payments: ${_calculation!.paymentSchedule.length} months',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Month')),
                            DataColumn(label: Text('Due Date')),
                            DataColumn(label: Text('Payment')),
                            DataColumn(label: Text('Principal')),
                            DataColumn(label: Text('Interest')),
                            DataColumn(label: Text('Outstanding')),
                          ],
                          rows: _calculation!.paymentSchedule
                              .map((payment) => DataRow(
                                    cells: [
                                      DataCell(Text('${payment.month}')),
                                      DataCell(Text(_calculation!
                                          .formatDate(payment.dueDate))),
                                      DataCell(Text(_calculation!
                                          .formatCurrency(payment.payment))),
                                      DataCell(Text(_calculation!
                                          .formatCurrency(payment.principal))),
                                      DataCell(Text(_calculation!
                                          .formatCurrency(payment.interest))),
                                      DataCell(Text(_calculation!
                                          .formatCurrency(
                                              payment.outstandingBalance))),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Settlement Calculator
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
                            Icons.calculate,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Settlement Calculator',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Calculate the exact payoff amount on any date after making k monthly payments.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Outstanding Balance after k payments:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Text(
                            _calculation!.formatCurrency(
                                _calculation!.calculateOutstandingBalance(6)),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: After 6 monthly payments',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveCalculationDialog extends StatefulWidget {
  const _SaveCalculationDialog();

  @override
  State<_SaveCalculationDialog> createState() => _SaveCalculationDialogState();
}

class _SaveCalculationDialogState extends State<_SaveCalculationDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Calculation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Calculation Name',
                hintText: 'Enter a name for this calculation',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
