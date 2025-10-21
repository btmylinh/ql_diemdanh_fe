import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class ActivitiesRepository {
  ActivitiesRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> list({
    int page = 1,
    int limit = 10,
    String? q,
    String? dateIso,
  }) async {
    final res = await _dio.get('/activities', queryParameters: {
      'page': page,
      'limit': limit,
      if (q != null && q.isNotEmpty) 'q': q,
      if (dateIso != null && dateIso.isNotEmpty) 'date': dateIso,
      'sortBy': 'startTime',
      'sortOrder': 'asc',
      'status': 2,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final res = await _dio.get('/activities/$id');
    return Map<String, dynamic>.from(res.data['activity']);
  }
}

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(buildDio());
});



