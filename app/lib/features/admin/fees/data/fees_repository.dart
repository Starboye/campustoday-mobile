import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  return FeesRepository(ref.watch(dioProvider));
});

class FeesRepository {
  FeesRepository(this._dio);

  final Dio _dio;

  Future<List<FeeStructure>> listStructures() async {
    final data = await _dio.adminGet<dynamic>('/admin/fees/structures');
    return parseListData(data).map(FeeStructure.fromJson).toList();
  }

  Future<List<FeePayment>> listPayments({String? status}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/fees/payments',
      queryParameters: status != null ? {'status': status} : null,
    );
    return parseListData(data).map(FeePayment.fromJson).toList();
  }
}

class FeeStructure {
  const FeeStructure({required this.id, required this.name, required this.amount, required this.term});

  final String id;
  final String name;
  final double amount;
  final String term;

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: '${json['id']}',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      term: json['term']?.toString() ?? '',
    );
  }
}

class FeePayment {
  const FeePayment({
    required this.id,
    required this.studentName,
    required this.amount,
    required this.status,
  });

  final String id;
  final String studentName;
  final double amount;
  final String status;

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: '${json['id']}',
      studentName: json['student_name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }
}
