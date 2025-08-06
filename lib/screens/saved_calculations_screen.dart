import 'package:flutter/material.dart';
import '../models/saved_calculation.dart';
import '../services/saved_calculations_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'calculator_screen.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({super.key});

  @override
  State<SavedCalculationsScreen> createState() =>
      _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  List<SavedCalculation> _savedCalculations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCalculations();
  }

  Future<void> _loadSavedCalculations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calculations =
          await SavedCalculationsService.getAllSavedCalculations();
      setState(() {
        _savedCalculations = calculations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading saved calculations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCalculation(SavedCalculation calculation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calculation'),
        content: Text('Are you sure you want to delete "${calculation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success =
            await SavedCalculationsService.deleteCalculation(calculation.id);
        if (success) {
          await _loadSavedCalculations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calculation deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting calculation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editCalculation(SavedCalculation calculation) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditCalculationDialog(calculation: calculation),
    );

    if (result != null) {
      try {
        final updatedCalculation = calculation.copyWith(
          name: result['name'],
        );

        final success = await SavedCalculationsService.updateCalculation(
            updatedCalculation);
        if (success) {
          await _loadSavedCalculations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calculation updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating calculation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadCalculation(SavedCalculation calculation) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CalculatorScreen(
          savedCalculation: calculation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Saved Calculations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_savedCalculations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () => _showClearAllDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedCalculations.isEmpty
              ? _buildEmptyState()
              : _buildCalculationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.save_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Calculations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your calculations to access them later',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedCalculations.length,
      itemBuilder: (context, index) {
        final calculation = _savedCalculations[index];
        return _buildCalculationCard(calculation);
      },
    );
  }

  Widget _buildCalculationCard(SavedCalculation calculation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              calculation.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Principal: ${Formatters.formatCurrency(calculation.calculation.principal)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Term: ${calculation.calculation.loanTerm} years',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly: ${Formatters.formatCurrency(calculation.calculation.monthlyPayment)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved: ${Formatters.formatDate(calculation.savedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'load':
                    _loadCalculation(calculation);
                    break;
                  case 'edit':
                    _editCalculation(calculation);
                    break;
                  case 'delete':
                    _deleteCalculation(calculation);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'load',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Load'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton.icon(
              onPressed: () => _loadCalculation(calculation),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Load Calculation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Calculations'),
        content: const Text(
            'Are you sure you want to delete all saved calculations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SavedCalculationsService.clearAllCalculations();
        await _loadSavedCalculations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All calculations cleared'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing calculations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EditCalculationDialog extends StatefulWidget {
  final SavedCalculation calculation;

  const _EditCalculationDialog({required this.calculation});

  @override
  State<_EditCalculationDialog> createState() => _EditCalculationDialogState();
}

class _EditCalculationDialogState extends State<_EditCalculationDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.calculation.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Calculation'),
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
