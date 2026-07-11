// lib/presentation/providers/image_upload_provider.dart

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/remote/api/image_upload_service.dart';
import 'profile_provider.dart';

sealed class ImageUploadState {
  const ImageUploadState();
}

class ImageUploadIdle extends ImageUploadState {
  const ImageUploadIdle();
}

class ImageUploadLoading extends ImageUploadState {
  const ImageUploadLoading();
}

class ImageUploadSuccess extends ImageUploadState {
  const ImageUploadSuccess({required this.imageUrl});
  final String? imageUrl;
}

class ImageUploadError extends ImageUploadState {
  const ImageUploadError({required this.message});
  final String message;
}

class ImageUploadNotifier extends StateNotifier<ImageUploadState> {
  ImageUploadNotifier({
    required Ref ref,
    ImageUploadService? service,
    ImagePicker? picker,
  })  : _ref = ref,
        _service = service ?? ImageUploadService(),
        _picker = picker ?? ImagePicker(),
        super(const ImageUploadIdle());

  final Ref _ref;
  final ImageUploadService _service;
  final ImagePicker _picker;

  Future<File?> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  Future<void> _handleUpload(Future<String?> Function(File) upload) async {
    try {
      final file = await _pickImage();
      if (file == null) return;

      state = const ImageUploadLoading();
      final imageUrl = await upload(file);
      state = ImageUploadSuccess(imageUrl: imageUrl);
    } on ImageUploadException catch (e) {
      state = ImageUploadError(message: e.message);
    } catch (e) {
      state = ImageUploadError(message: 'Error inesperado: ${e.toString()}');
    }
  }

  Future<void> pickAndUploadProductImage(int productId) async {
    await _handleUpload(
      (file) => _service.uploadProductImage(productId: productId, file: file),
    );
  }

  Future<void> pickAndUploadAvatar() async {
    await _handleUpload(
      (file) => _service.uploadAvatar(file: file),
    );

    if (state is ImageUploadSuccess) {
      _ref.invalidate(profileProvider);
    }
  }

  void reset() => state = const ImageUploadIdle();
}

final imageUploadProvider =
    StateNotifierProvider.autoDispose<ImageUploadNotifier, ImageUploadState>(
  (ref) => ImageUploadNotifier(ref: ref),
);