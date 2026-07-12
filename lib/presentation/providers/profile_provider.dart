// lib/presentation/providers/profile_provider.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/api_exception.dart';
import '../../data/remote/api/dio_client.dart';
import '../../domain/model/user_profile.dart';

sealed class ProfileFormState { const ProfileFormState(); }
class ProfileFormIdle extends ProfileFormState { const ProfileFormIdle(); }
class ProfileFormSaving extends ProfileFormState { const ProfileFormSaving(); }
class ProfileFormSuccess extends ProfileFormState {
  final String message;
  const ProfileFormSuccess(this.message);
}
class ProfileFormError extends ProfileFormState {
  final String message;
  const ProfileFormError(this.message);
}

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final ProfileFormState formState;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.formState = const ProfileFormIdle(),
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    ProfileFormState? formState,
  }) =>
      ProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        formState: formState ?? this.formState,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Dio _dio;

  ProfileNotifier(this._dio) : super(const ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get('/clientes/perfil/');
      final profile = UserProfile.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(profile: profile, isLoading: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // El perfil de cliente no existe aún (caso típico tras registrarse)
        state = state.copyWith(
          profile: const UserProfile(
            idPerfil: 0,
            username: '',
            email: '',
            cedula: '',
            telefono: '',
            direccion: '',
            fotoPerfil: null,
            fechaNacimiento: null,
          ),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: ApiException.fromDioError(e).message,
        );
      }
    }
  }

  void resetFormState() => state = state.copyWith(formState: const ProfileFormIdle());

  Future<void> updateProfile({
    required String cedula,
    required String telefono,
    required String direccion,
    String? fechaNacimiento,
    File? fotoFile,
  }) async {
    state = state.copyWith(formState: const ProfileFormSaving());
    try {
      final data = <String, dynamic>{
        'cedula': cedula,
        'telefono': telefono,
        'direccion': direccion,
        if (fechaNacimiento != null && fechaNacimiento.isNotEmpty)
          'fecha_nacimiento': fechaNacimiento,
      };

      if (fotoFile != null) {
        final filename = fotoFile.path.split('/').last;
        data['foto_perfil'] = await MultipartFile.fromFile(
          fotoFile.path,
          filename: filename,
        );
      }

      final formData = FormData.fromMap(data);
      // El backend soporta POST como upsert (/clientes/perfil/)
      final res = await _dio.post('/clientes/perfil/', data: formData);
      final updatedProfile = UserProfile.fromJson(res.data as Map<String, dynamic>);

      state = state.copyWith(
        profile: updatedProfile,
        formState: const ProfileFormSuccess('Perfil guardado con éxito'),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        formState: ProfileFormError(ApiException.fromDioError(e).message),
      );
    }
  }
}

final profileProvider = StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(dioProvider));
});