class FeeTerm {
  const FeeTerm({
    required this.termId,
    required this.termName,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    this.dueDate,
  });

  final int termId;
  final String termName;
  final double amountDue;
  final double amountPaid;
  final String status;
  final String? dueDate;

  factory FeeTerm.fromJson(Map<String, dynamic> json) {
    return FeeTerm(
      termId: json['term_id'] as int? ?? json['id'] as int? ?? 0,
      termName: json['term_name'] as String? ?? json['term'] as String? ?? '',
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] as String?,
    );
  }
}

class FeesResponse {
  const FeesResponse({required this.items});

  final List<FeeTerm> items;

  factory FeesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? json['terms'] as List<dynamic>? ?? [];
    return FeesResponse(
      items: list.map((e) => FeeTerm.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
