import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class ImageUploadException implements Exception {
  const ImageUploadException(this.message);
  final String message;

  @override
  String toString() => 'ImageUploadException: $message';
}

class ImageUploadService {
  ImageUploadService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> _readToken() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        final altToken = await _storage.read(key: 'token');
        if (altToken != null && altToken.isNotEmpty) {
          await _storage.write(key: 'access_token', value: altToken);
          return altToken;
        }
        return null;
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _upload({
    required Uri uri,
    required String fieldName,
    required File file,
  }) async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      throw const ImageUploadException('No autenticado. Inicia sesión primero.');
    }

    final mimeType = _mimeTypeFromPath(file.path);

    final request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll(_authHeaders(token))
      ..files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: mimeType,
        ),
      );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw const ImageUploadException(
          'La solicitud tardó demasiado. Verifica tu conexión.',
        );
      },
    );

    final response = await http.Response.fromStream(streamedResponse);
    
    String responseBody;
    try {
      responseBody = utf8.decode(response.bodyBytes);
    } catch (e) {
      responseBody = response.body;
    }
    
    final body = jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    final detail = _extractError(body);
    throw ImageUploadException(detail);
  }

  String _extractError(Map<String, dynamic> body) {
    if (body.containsKey('detail')) return body['detail'].toString();
    if (body.containsKey('message')) return body['message'].toString();
    if (body.containsKey('error')) return body['error'].toString();
    if (body.containsKey('image')) {
      final v = body['image'];
      return v is List ? v.first.toString() : v.toString();
    }
    if (body.containsKey('avatar')) {
      final v = body['avatar'];
      return v is List ? v.first.toString() : v.toString();
    }
    if (body.containsKey('non_field_errors')) {
      final v = body['non_field_errors'];
      return v is List ? v.first.toString() : v.toString();
    }
    return 'Error desconocido al subir la imagen.';
  }

  http.MediaType _mimeTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => http.MediaType('image', 'jpeg'),
      'png'           => http.MediaType('image', 'png'),
      'webp'          => http.MediaType('image', 'webp'),
      _               => http.MediaType('image', 'jpeg'),
    };
  }

  Future<String?> uploadProductImage({
    required int productId,
    required File file,
  }) async {
    final uri  = Uri.parse('${AppConfig.baseUrl}/products/$productId/');
    final body = await _upload(uri: uri, fieldName: 'image', file: file);
    return body['image_url'] as String?;
  }

  Future<String?> uploadAvatar({required File file}) async {
    final uri  = Uri.parse('${AppConfig.baseUrl}/users/profile/');
    final body = await _upload(uri: uri, fieldName: 'avatar', file: file);
    return body['avatar_url'] as String?;
  }
}