

import 'dart:io';
import 'package:dio/dio.dart';
import '../configurations/api_config.dart';
import '../utils/image_compressor.dart';

/// API Service for communicating with the Flask backend
class ApiService {
  late Dio _dio;
  static ApiService? _instance;

  /// Private constructor
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    ));

    // Add logging interceptor for debug mode
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('API Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('API Response: ${response.statusCode} ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          print('Response: ${error.response}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Get singleton instance
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  /// Upload X-ray image and get prediction
  ///
  /// Parameters:
  /// - [imagePath]: Path to the image file
  ///
  /// Returns prediction data with image URL
  Future<Map<String, dynamic>> uploadXrayForPrediction(String imagePath) async {
    try {
      final file = File(imagePath);

      // Validate file
      if (!file.existsSync()) {
        throw Exception('Image file not found');
      }

      if (!ImageCompressor.isImageFile(file)) {
        throw Exception('Invalid image file format');
      }

      // Compress image
      final compressedFile = await ImageCompressor.compressImage(file);
      print('Compressed image size: ${ImageCompressor.getFileSizeMb(compressedFile).toStringAsFixed(2)} MB');

      // Prepare form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedFile.path,
          filename: compressedFile.path.split('/').last,
        ),
      });

      // Send request
      final response = await _dio.post(
        ApiConfig.predictEndpoint,
        data: formData,
      );

      // Parse response
      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['error'] ?? 'Prediction failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please ensure the API is running.');
      }
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(ApiConfig.healthEndpoint);
      return response.statusCode == 200 && response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  /// Get Dio instance for custom requests
  Dio get dio => _dio;
}
