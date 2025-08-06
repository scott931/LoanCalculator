import '../utils/formatters.dart';
import 'dart:math' as math;

class LoanCalculation {
  final double principal;
  final double monthlyInterestRate;
  final double annualInterestRate;
  final int loanTerm;
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
  final DateTime loanDate;
  final double laceFee;
  final double insuranceFee;
  final double disbursementFee;
  final double totalFees;
  final List<PaymentSchedule> paymentSchedule;

  LoanCalculation({
    required this.principal,
    required this.monthlyInterestRate,
    required this.annualInterestRate,
    required this.loanTerm,
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.loanDate,
    required this.laceFee,
    required this.insuranceFee,
    required this.disbursementFee,
    required this.totalFees,
    required this.paymentSchedule,
  });

  // Calculate outstanding balance after k monthly installments
  double calculateOutstandingBalance(int k) {
    if (k <= 0) return principal;

    double r = monthlyInterestRate;
    double pmt = monthlyPayment;

    // B_k = P(1+r)^k - (PMT/r)((1+r)^k - 1)
    double balance =
        principal * math.pow(1 + r, k) - (pmt / r) * (math.pow(1 + r, k) - 1);

    return balance > 0 ? balance : 0;
  }

  // Calculate settlement amount on any calendar date
  double calculateSettlementAmount(DateTime settlementDate, int k) {
    double outstandingBalance = calculateOutstandingBalance(k);

    // Calculate days since kth due date
    DateTime kthDueDate = DateTime(
      loanDate.year + ((loanDate.month + k - 1) ~/ 12),
      ((loanDate.month + k - 1) % 12) + 1,
      loanDate.day,
    );
    int daysElapsed = settlementDate.difference(kthDueDate).inDays;

    if (daysElapsed <= 0) return outstandingBalance;

    double r = monthlyInterestRate;
    double d = daysElapsed.toDouble();
    double daysInMonth = 30.4375;

    // Settlement = B_k + B_k * r * (d / 30.4375)
    double settlement =
        outstandingBalance + outstandingBalance * r * (d / daysInMonth);

    return settlement;
  }

  // Get formatted currency string
  String formatCurrency(double amount) {
    return Formatters.formatCurrency(amount);
  }

  // Get formatted date string
  String formatDate(DateTime date) {
    return Formatters.formatDate(date);
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'principal': principal,
      'monthlyInterestRate': monthlyInterestRate,
      'annualInterestRate': annualInterestRate,
      'loanTerm': loanTerm,
      'monthlyPayment': monthlyPayment,
      'totalPayment': totalPayment,
      'totalInterest': totalInterest,
      'loanDate': loanDate.millisecondsSinceEpoch,
      'laceFee': laceFee,
      'insuranceFee': insuranceFee,
      'disbursementFee': disbursementFee,
      'totalFees': totalFees,
      'paymentSchedule': paymentSchedule.map((ps) => ps.toJson()).toList(),
    };
  }

  // Create from JSON
  factory LoanCalculation.fromJson(Map<String, dynamic> json) {
    return LoanCalculation(
      principal: json['principal'].toDouble(),
      monthlyInterestRate: json['monthlyInterestRate'].toDouble(),
      annualInterestRate: json['annualInterestRate'].toDouble(),
      loanTerm: json['loanTerm'],
      monthlyPayment: json['monthlyPayment'].toDouble(),
      totalPayment: json['totalPayment'].toDouble(),
      totalInterest: json['totalInterest'].toDouble(),
      loanDate: DateTime.fromMillisecondsSinceEpoch(json['loanDate']),
      laceFee: json['laceFee'].toDouble(),
      insuranceFee: json['insuranceFee'].toDouble(),
      disbursementFee: json['disbursementFee'].toDouble(),
      totalFees: json['totalFees'].toDouble(),
      paymentSchedule: (json['paymentSchedule'] as List)
          .map((ps) => PaymentSchedule.fromJson(ps))
          .toList(),
    );
  }
}

class PaymentSchedule {
  final int month;
  final DateTime dueDate;
  final double payment;
  final double principal;
  final double interest;
  final double remainingBalance;
  final double outstandingBalance;

  PaymentSchedule({
    required this.month,
    required this.dueDate,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.remainingBalance,
    required this.outstandingBalance,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'payment': payment,
      'principal': principal,
      'interest': interest,
      'remainingBalance': remainingBalance,
      'outstandingBalance': outstandingBalance,
    };
  }

  // Create from JSON
  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      month: json['month'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
      payment: json['payment'].toDouble(),
      principal: json['principal'].toDouble(),
      interest: json['interest'].toDouble(),
      remainingBalance: json['remainingBalance'].toDouble(),
      outstandingBalance: json['outstandingBalance'].toDouble(),
    );
  }
}

// Fee structure constants
class LoanFees {
  static const double ANNUAL_INTEREST_RATE = 36.09;
  static const double MONTHLY_INTEREST_RATE = 2.60;
  static const double LACE_FEE_PERCENTAGE = 4.0;
  static const double INSURANCE_FEE_PERCENTAGE = 1.0;
  static const double DISBURSEMENT_FEE = 700.0;
}
