import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class FeeBreakdownCard extends StatelessWidget {
  final double laceFee;
  final double insuranceFee;
  final double disbursementFee;
  final double totalFees;

  const FeeBreakdownCard({
    Key? key,
    required this.laceFee,
    required this.insuranceFee,
    required this.disbursementFee,
    required this.totalFees,
  }) : super(key: key);

  Widget _buildFeeRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.grey[600],
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                Icons.receipt_long,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fee Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeeRow('LACE Fee (4%)', laceFee),
          _buildFeeRow('Insurance Fee (1%)', insuranceFee),
          _buildFeeRow('Disbursement Fee', disbursementFee),
          const Divider(height: 24),
          _buildFeeRow(
            'Total Fees',
            totalFees,
            color: Colors.blue[600],
          ),
        ],
      ),
    );
  }
}
