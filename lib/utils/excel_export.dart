import 'dart:io';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/loan_calculation.dart';
import '../utils/formatters.dart';

class ExcelExport {
  static Future<void> exportToExcel(
    LoanCalculation calculation, {
    int? paymentsMade,
    DateTime? settlementDate,
  }) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Loan Schedule'];

      // Add loan summary at the top
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value = 'LOAN SUMMARY'
        ..cellStyle = CellStyle(bold: true, fontSize: 16);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        ..value = 'Principal Amount'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
        ..value = calculation.formatCurrency(calculation.principal);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        ..value = 'Annual Interest Rate'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        ..value = '${calculation.annualInterestRate}%';

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        ..value = 'Monthly Payment'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        ..value = calculation.formatCurrency(calculation.monthlyPayment);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        ..value = 'Loan Term'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        ..value = '${calculation.loanTerm} years';

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        ..value = 'Loan Date'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        ..value = calculation.formatDate(calculation.loanDate);

      // Add fee breakdown
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        ..value = 'FEE BREAKDOWN'
        ..cellStyle = CellStyle(bold: true, fontSize: 14);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        ..value = 'LACE Fee (4%)'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        ..value = calculation.formatCurrency(calculation.laceFee);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        ..value = 'Insurance Fee (1%)'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        ..value = calculation.formatCurrency(calculation.insuranceFee);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        ..value = 'Disbursement Fee'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        ..value = calculation.formatCurrency(calculation.disbursementFee);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11))
        ..value = 'Total Fees'
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11))
        ..value = calculation.formatCurrency(calculation.totalFees);

      // Add early payment calculation if provided
      int currentRow = 13;
      if (paymentsMade != null && settlementDate != null) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          ..value = 'EARLY PAYMENT CALCULATION'
          ..cellStyle = CellStyle(bold: true, fontSize: 14);

        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: currentRow + 1))
          ..value = 'Payments Made'
          ..cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: currentRow + 1))
          ..value = paymentsMade;

        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: currentRow + 2))
          ..value = 'Settlement Date'
          ..cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: currentRow + 2))
          ..value = Formatters.formatDate(settlementDate);

        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: currentRow + 3))
          ..value = 'Early Settlement Amount'
          ..cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: currentRow + 3))
          ..value = Formatters.formatCurrency(calculation
              .calculateSettlementAmount(settlementDate, paymentsMade));

        currentRow += 5; // Move to next section
      }

      // Add payment schedule
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = 'PAYMENT SCHEDULE'
        ..cellStyle = CellStyle(bold: true, fontSize: 14);

      // Set headers for payment schedule
      final headers = [
        'Month',
        'Due Date',
        'Payment',
        'Principal',
        'Interest',
        'Remaining Balance',
        'Outstanding Balance',
      ];

      // Add schedule headers
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i, rowIndex: currentRow + 1))
          ..value = headers[i]
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: '#E3F2FD',
          );
      }

      // Add payment schedule data
      for (int i = 0; i < calculation.paymentSchedule.length; i++) {
        final payment = calculation.paymentSchedule[i];
        final row = currentRow + 2 + i;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          ..value = payment.month;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          ..value = calculation.formatDate(payment.dueDate);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          ..value = calculation.formatCurrency(payment.payment);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          ..value = calculation.formatCurrency(payment.principal);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          ..value = calculation.formatCurrency(payment.interest);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          ..value = calculation.formatCurrency(payment.remainingBalance);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          ..value = calculation.formatCurrency(payment.outstandingBalance);
      }

      // Note: Column width setting is not available in this version of the excel package

      // Platform-specific file handling
      if (kIsWeb) {
        // Web platform - use blob download
        final bytes = excel.encode()!;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download',
              'loan_schedule_${DateTime.now().millisecondsSinceEpoch}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile/Desktop platforms - use path_provider and share
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName =
              'loan_schedule_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File('${directory.path}/$fileName');

          await file.writeAsBytes(excel.encode()!);

          // Share the file
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Loan Schedule',
            text:
                'Loan calculation schedule exported from Loan Calculator app.',
          );
        } catch (e) {
          // Fallback for platforms where path_provider doesn't work
          throw Exception(
              'Export not supported on this platform. Please use a mobile device or desktop.');
        }
      }
    } catch (e) {
      throw Exception('Failed to export Excel file: $e');
    }
  }

  // Alternative CSV export for web platforms
  static Future<void> exportToCSV(
    LoanCalculation calculation, {
    int? paymentsMade,
    DateTime? settlementDate,
  }) async {
    try {
      final csvData = StringBuffer();

      // Add loan summary
      csvData.writeln('LOAN SUMMARY');
      csvData.writeln(
          'Principal Amount,${calculation.formatCurrency(calculation.principal)}');
      csvData
          .writeln('Annual Interest Rate,${calculation.annualInterestRate}%');
      csvData.writeln(
          'Monthly Payment,${calculation.formatCurrency(calculation.monthlyPayment)}');
      csvData.writeln('Loan Term,${calculation.loanTerm} years');
      csvData
          .writeln('Loan Date,${calculation.formatDate(calculation.loanDate)}');
      csvData.writeln();

      // Add fee breakdown
      csvData.writeln('FEE BREAKDOWN');
      csvData.writeln(
          'LACE Fee (4%),${calculation.formatCurrency(calculation.laceFee)}');
      csvData.writeln(
          'Insurance Fee (1%),${calculation.formatCurrency(calculation.insuranceFee)}');
      csvData.writeln(
          'Disbursement Fee,${calculation.formatCurrency(calculation.disbursementFee)}');
      csvData.writeln(
          'Total Fees,${calculation.formatCurrency(calculation.totalFees)}');
      csvData.writeln();

      // Add early payment calculation if provided
      if (paymentsMade != null && settlementDate != null) {
        csvData.writeln('EARLY PAYMENT CALCULATION');
        csvData.writeln('Payments Made,$paymentsMade');
        csvData.writeln(
            'Settlement Date,${Formatters.formatDate(settlementDate)}');
        csvData.writeln(
            'Early Settlement Amount,${Formatters.formatCurrency(calculation.calculateSettlementAmount(settlementDate, paymentsMade))}');
        csvData.writeln();
      }

      // Add payment schedule
      csvData.writeln('PAYMENT SCHEDULE');
      csvData.writeln(
          'Month,Due Date,Payment,Principal,Interest,Remaining Balance,Outstanding Balance');

      for (final payment in calculation.paymentSchedule) {
        csvData.writeln(
            '${payment.month},${calculation.formatDate(payment.dueDate)},${calculation.formatCurrency(payment.payment)},${calculation.formatCurrency(payment.principal)},${calculation.formatCurrency(payment.interest)},${calculation.formatCurrency(payment.remainingBalance)},${calculation.formatCurrency(payment.outstandingBalance)}');
      }

      if (kIsWeb) {
        // Web platform - use blob download for CSV
        final bytes = csvData.toString().codeUnits;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download',
              'loan_schedule_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile/Desktop platforms
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName =
              'loan_schedule_${DateTime.now().millisecondsSinceEpoch}.csv';
          final file = File('${directory.path}/$fileName');

          await file.writeAsString(csvData.toString());

          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Loan Schedule (CSV)',
            text:
                'Loan calculation schedule exported from Loan Calculator app.',
          );
        } catch (e) {
          throw Exception('CSV export not supported on this platform.');
        }
      }
    } catch (e) {
      throw Exception('Failed to export CSV file: $e');
    }
  }
}
