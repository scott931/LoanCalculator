import 'loan_calculation.dart';

class SavedCalculation {
  final String id;
  final String name;
  final DateTime savedAt;
  final LoanCalculation calculation;
  final Map<String, dynamic> inputData;

  SavedCalculation({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.calculation,
    required this.inputData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'savedAt': savedAt.millisecondsSinceEpoch,
      'calculation': calculation.toJson(),
      'inputData': inputData,
    };
  }

  factory SavedCalculation.fromJson(Map<String, dynamic> json) {
    return SavedCalculation(
      id: json['id'],
      name: json['name'],
      savedAt: DateTime.fromMillisecondsSinceEpoch(json['savedAt']),
      calculation: LoanCalculation.fromJson(json['calculation']),
      inputData: Map<String, dynamic>.from(json['inputData']),
    );
  }

  SavedCalculation copyWith({
    String? id,
    String? name,
    DateTime? savedAt,
    LoanCalculation? calculation,
    Map<String, dynamic>? inputData,
  }) {
    return SavedCalculation(
      id: id ?? this.id,
      name: name ?? this.name,
      savedAt: savedAt ?? this.savedAt,
      calculation: calculation ?? this.calculation,
      inputData: inputData ?? this.inputData,
    );
  }
}
