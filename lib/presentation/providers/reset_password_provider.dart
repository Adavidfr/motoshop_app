// lib/presentation/providers/reset_password_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/auth_remote_datasource.dart';

sealed class ResetPasswordState {
  const ResetPasswordState();
}

class ResetPasswordIdle    extends ResetPasswordState { const ResetPasswordIdle(); }
class ResetPasswordLoading extends ResetPasswordState { const ResetPasswordLoading(); }
class ResetPasswordSuccess extends ResetPasswordState { const ResetPasswordSuccess(); }

class ResetPasswordError extends ResetPasswordState {
  final String message;
  const ResetPasswordError(this.message);
}

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  final AuthRemoteDatasource _datasource;

  ResetPasswordNotifier(this._datasource) : super(const ResetPasswordIdle());

  Future<void> confirmReset({
    required String uid,
    required String token,
    required String newPassword,
    required String newPassword2,
  }) async {
    if (state is ResetPasswordLoading) return;
    state = const ResetPasswordLoading();
    try {
      await _datasource.confirmPasswordReset(
        uid:          uid.trim(),
        token:        token.trim(),
        newPassword:  newPassword,
        newPassword2: newPassword2,
      );
      state = const ResetPasswordSuccess();
    } catch (e) {
      state = ResetPasswordError(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    if (state is ResetPasswordError) state = const ResetPasswordIdle();
  }
}

final resetPasswordProvider = StateNotifierProvider.autoDispose<
    ResetPasswordNotifier, ResetPasswordState>((ref) {
  return ResetPasswordNotifier(ref.watch(authDatasourceProvider));
});