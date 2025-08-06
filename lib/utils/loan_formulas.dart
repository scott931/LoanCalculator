import 'dart:math' as math;
import '../models/loan_calculation.dart';
import 'settings_service.dart';

class LoanFormulas {
  // Calculate monthly payment using the standard loan formula
  static double calculateMonthlyPayment(
      double principal, double monthlyRate, int months) {
    if (monthlyRate == 0) return principal / months;

    return principal *
        (monthlyRate * math.pow(1 + monthlyRate, months)) /
        (math.pow(1 + monthlyRate, months) - 1);
  }

  // Calculate fees based on the specified structure
  static Future<Map<String, double>> calculateFees(double principal) async {
    final laceFeePercentage = await SettingsService.getLaceFeePercentage();
    final insuranceFeePercentage =
        await SettingsService.getInsuranceFeePercentage();
    final disbursementFee = await SettingsService.getDisbursementFee();

    double laceFee = principal * (laceFeePercentage / 100);
    double insuranceFee = principal * (insuranceFeePercentage / 100);
    double totalFees = laceFee + insuranceFee + disbursementFee;

    return {
      'laceFee': laceFee,
      'insuranceFee': insuranceFee,
      'disbursementFee': disbursementFee,
      'totalFees': totalFees,
    };
  }

  // Generate payment schedule with outstanding balance calculations
  static List<PaymentSchedule> generatePaymentSchedule({
    required double principal,
    required double monthlyRate,
    required int months,
    required DateTime loanDate,
    required double monthlyPayment,
  }) {
    List<PaymentSchedule> schedule = [];
    double remainingBalance = principal;

    for (int month = 1; month <= months; month++) {
      double interest = remainingBalance * monthlyRate;
      double principalPayment = monthlyPayment - interest;
      remainingBalance -= principalPayment;

      if (remainingBalance < 0) remainingBalance = 0;

      // Calculate due date (monthly from loan date)
      DateTime dueDate = DateTime(
        loanDate.year + ((loanDate.month + month - 2) ~/ 12),
        ((loanDate.month + month - 2) % 12) + 1,
        loanDate.day,
      );

      // Calculate outstanding balance using the formula
      double outstandingBalance = calculateOutstandingBalance(
          principal, monthlyRate, monthlyPayment, month - 1);

      schedule.add(PaymentSchedule(
        month: month,
        dueDate: dueDate,
        payment: monthlyPayment,
        principal: principalPayment,
        interest: interest,
        remainingBalance: remainingBalance,
        outstandingBalance: outstandingBalance,
      ));
    }

    return schedule;
  }

  // Calculate outstanding balance after k monthly installments
  static double calculateOutstandingBalance(
      double principal, double monthlyRate, double monthlyPayment, int k) {
    if (k <= 0) return principal;

    // B_k = P(1+r)^k - (PMT/r)((1+r)^k - 1)
    double balance = principal * math.pow(1 + monthlyRate, k) -
        (monthlyPayment / monthlyRate) * (math.pow(1 + monthlyRate, k) - 1);

    return balance > 0 ? balance : 0;
  }

  // Calculate settlement amount on any calendar date
  static double calculateSettlementAmount({
    required double principal,
    required double monthlyRate,
    required double monthlyPayment,
    required int k,
    required DateTime loanDate,
    required DateTime settlementDate,
  }) {
    double outstandingBalance =
        calculateOutstandingBalance(principal, monthlyRate, monthlyPayment, k);

    // Calculate days since kth due date
    DateTime kthDueDate = DateTime(
      loanDate.year + ((loanDate.month + k - 1) ~/ 12),
      ((loanDate.month + k - 1) % 12) + 1,
      loanDate.day,
    );
    int daysElapsed = settlementDate.difference(kthDueDate).inDays;

    if (daysElapsed <= 0) return outstandingBalance;

    double d = daysElapsed.toDouble();
    double daysInMonth = 30.4375;

    // Settlement = B_k + B_k * r * (d / 30.4375)
    double settlement = outstandingBalance +
        outstandingBalance * monthlyRate * (d / daysInMonth);

    return settlement;
  }

  // Main calculation function
  static Future<LoanCalculation> calculateLoan({
    required double principal,
    required int loanTerm,
    required double monthlyPayment,
    required DateTime loanDate,
  }) async {
    final monthlyRate = await SettingsService.getMonthlyInterestRate() / 100;
    final annualRate = await SettingsService.getAnnualInterestRate();
    int months = loanTerm * 12;

    // Calculate fees
    Map<String, double> fees = await calculateFees(principal);

    // Calculate totals
    double totalPayment = monthlyPayment * months;
    double totalInterest = totalPayment - principal;

    // Generate payment schedule
    List<PaymentSchedule> schedule = generatePaymentSchedule(
      principal: principal,
      monthlyRate: monthlyRate,
      months: months,
      loanDate: loanDate,
      monthlyPayment: monthlyPayment,
    );

    return LoanCalculation(
      principal: principal,
      monthlyInterestRate: monthlyRate,
      annualInterestRate: annualRate,
      loanTerm: loanTerm,
      monthlyPayment: monthlyPayment,
      totalPayment: totalPayment,
      totalInterest: totalInterest,
      loanDate: loanDate,
      laceFee: fees['laceFee']!,
      insuranceFee: fees['insuranceFee']!,
      disbursementFee: fees['disbursementFee']!,
      totalFees: fees['totalFees']!,
      paymentSchedule: schedule,
    );
  }
}
