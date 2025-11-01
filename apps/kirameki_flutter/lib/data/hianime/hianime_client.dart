import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kirameki_flutter/data/hianime/models/anime_summary.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_stream.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_summary.dart';
import 'package:kirameki_flutter/data/hianime/models/home_catalog.dart';

class HiAnimeApiClient {
  HiAnimeApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            ) {
    if ((_dio.options.baseUrl).isEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    final headers = Map<String, Object?>.from(_dio.options.headers);
    headers['Accept'] = 'application/json';
    _dio.options.headers = headers;
  }

  static const baseUrl = 'https://hianime-api-qdks.onrender.com/api/v1';

  final Dio _dio;

  Future<HomeCatalog> fetchHomeCatalog() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/home');
      final data = _unwrapData(response);

      final spotlight = (data['spotlight'] as List<dynamic>? ?? [])
          .map((item) =>
              AnimeSummary.fromSpotlight(item as Map<String, dynamic>))
          .toList();

      final trending = (data['trending'] as List<dynamic>? ?? [])
          .map((item) =>
              AnimeSummary.fromSimpleList(item as Map<String, dynamic>))
          .toList();

      final mostPopular = (data['mostPopular'] as List<dynamic>? ?? [])
          .map((item) =>
              AnimeSummary.fromSimpleList(item as Map<String, dynamic>))
          .toList();

      final genres = (data['genres'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false);

      return HomeCatalog(
        spotlight: spotlight,
        trending: trending,
        mostPopular: mostPopular,
        genres: genres,
      );
    } on DioException catch (error) {
      throw HiAnimeApiException.fromDio(error);
    } catch (error, stackTrace) {
      throw HiAnimeApiException(
        message: 'Failed to parse home feed',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<AnimeSummary>> fetchMostPopular({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/animes/most-popular',
        queryParameters: {'page': page},
      );

      final data = _unwrapData(response);
      final responseList = data['response'] as List<dynamic>? ?? [];

      return responseList
          .map(
            (item) =>
                AnimeSummary.fromMostPopular(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw HiAnimeApiException.fromDio(error);
    } catch (error, stackTrace) {
      throw HiAnimeApiException(
        message: 'Failed to load most popular anime',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<EpisodeSummary>> fetchEpisodes(String animeId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/episodes/$animeId');
      final items = _unwrapList(response);

      return items
          .whereType<Map<String, dynamic>>()
          .map(EpisodeSummary.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw HiAnimeApiException.fromDio(error);
    } catch (error, stackTrace) {
      throw HiAnimeApiException(
        message: 'Failed to load episode list for $animeId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<EpisodeStream> fetchEpisodeStream({
    required String episodeId,
    String type = 'sub',
    String server = 'hd-2',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/stream',
        queryParameters: {
          'id': episodeId,
          'type': type,
          'server': server,
        },
      );

      final data = _unwrapData(response);
      return EpisodeStream.fromJson(data);
    } on DioException catch (error) {
      throw HiAnimeApiException.fromDio(error);
    } catch (error, stackTrace) {
      throw HiAnimeApiException(
        message: 'Failed to load episode stream',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic> _unwrapData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const HiAnimeApiException(message: 'Empty response body');
    }

    if (body['data'] == null) {
      throw HiAnimeApiException(
        message: 'Unexpected response structure',
        cause: body,
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw HiAnimeApiException(
        message: 'Expected map payload but received ${data.runtimeType}',
        cause: data,
      );
    }

    return data;
  }

  List<dynamic> _unwrapList(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const HiAnimeApiException(message: 'Empty response body');
    }

    final data = body['data'];
    if (data is! List<dynamic>) {
      throw HiAnimeApiException(
        message: 'Expected list payload but received ${data.runtimeType}',
        cause: data,
      );
    }

    return data;
  }
}

class HiAnimeApiException implements Exception {
  const HiAnimeApiException({
    required this.message,
    this.cause,
    this.stackTrace,
    this.statusCode,
  });

  factory HiAnimeApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    String message = error.message ?? 'Network error';

    if (data is Map<String, dynamic>) {
      final payloadMessage = data['message'];
      if (payloadMessage is String && payloadMessage.isNotEmpty) {
        message = payloadMessage;
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    return HiAnimeApiException(
      message: message,
      statusCode: statusCode,
      cause: error,
      stackTrace: error.stackTrace,
    );
  }

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final int? statusCode;

  @override
  String toString() {
    final buffer = StringBuffer('HiAnimeApiException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (cause != null) {
      buffer.write(' cause: ${jsonEncode(cause.toString())}');
    }
    return buffer.toString();
  }
}
