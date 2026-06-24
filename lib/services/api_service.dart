import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/transcription_job.dart';
import '../utils/constants.dart';

class ApiService {
  ApiService._()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 10),
          ),
        )..interceptors.add(_LogInterceptor());

  static final ApiService instance = ApiService._();
  final Dio _dio;

  // ── Upload ───────────────────────────────────────────────────────────[...]

  /// Upload audio + PPTX files and create a new transcription job.
  Future<TranscriptionJob> createJob({
    required Uint8List audioBytes,
    required String audioFilename,
    required Uint8List pptxBytes,
    required String pptxFilename,
    void Function(double progress)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'audio_file': MultipartFile.fromBytes(
        audioBytes,
        filename: audioFilename,
        contentType: DioMediaType.parse(_mimeForAudio(audioFilename)),
      ),
      'pptx_file': MultipartFile.fromBytes(
        pptxBytes,
        filename: pptxFilename,
        contentType: DioMediaType.parse(
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        ),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/transcriptions/',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onSendProgress?.call(sent / total);
      },
    );

    return TranscriptionJob.fromJson(response.data!);
  }

  // ── Poll / SSE ─────────────────────────────────────────────────────────��[...]

  /// Streams SSE progress events for a job.
  Stream<Map<String, dynamic>> streamProgress(String jobId) async* {
    final uri = Uri.parse('${ApiConfig.baseUrl}/transcriptions/$jobId/stream');
    final client = http.Client();

    try {
      final request = http.Request('GET', uri);
      final streamedResponse = await client.send(request);

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final buffer = StringBuffer();
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          buffer.write(line.substring(6));
        } else if (line.isEmpty && buffer.isNotEmpty) {
          final raw = buffer.toString();
          buffer.clear();
          try {
            yield jsonDecode(raw) as Map<String, dynamic>;
          } catch (_) {
            // Malformed SSE chunk – skip
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Fetch ───────────────────────────────────────────────────────────�[...]

  Future<TranscriptionJob> getJob(String jobId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transcriptions/$jobId',
    );
    return TranscriptionJob.fromJson(response.data!);
  }

  Future<List<TranscriptionJob>> listJobs({int skip = 0, int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transcriptions/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final items = response.data!['items'] as List<dynamic>;
    return items
        .map((e) => TranscriptionJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Export ──────────────────────────────────────────────────────────��[...]

  /// Returns the download URL for the export endpoint.
  String exportUrl(String jobId, String format) =>
      '${ApiConfig.baseUrl}/transcriptions/$jobId/export/$format';

  Future<Uint8List> downloadExport(String jobId, String format) async {
    final response = await _dio.get<List<int>>(
      '/transcriptions/$jobId/export/$format',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  // ── Helpers ──────────────────────────────────────────────────────────�[...]

  String _mimeForAudio(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return {
      'mp3':  'audio/mpeg',
      'wav':  'audio/wav',
      'm4a':  'audio/mp4',
      'mp4':  'audio/mp4',
      'ogg':  'audio/ogg',
      'webm': 'audio/webm',
      'flac': 'audio/flac',
    }[ext] ?? 'audio/mpeg';
  }
}

// ── Logging interceptor ───────────────────────────────────────────────────────
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] ✗ ${err.response?.statusCode} – ${err.message}');
    handler.next(err);
  }
}
