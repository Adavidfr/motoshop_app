import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motoshop_app/presentation/screens/admin/pagos_admin_screen.dart';
import 'package:motoshop_app/presentation/providers/auth_provider.dart';
import 'package:motoshop_app/domain/model/auth_state.dart';
import 'package:motoshop_app/domain/model/auth_models.dart';
import 'package:motoshop_app/data/local/secure_storage.dart';
import 'package:motoshop_app/data/remote/api/auth_remote_datasource.dart';

class DummyDatasource implements AuthRemoteDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyStorage implements SecureStorage {
  @override
  Future<bool> isLoggedIn() async => false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuthNotifierMock extends AuthNotifier {
  AuthNotifierMock() : super(DummyDatasource(), DummyStorage()) {
    state = AuthState.authenticated(LoggedUser(
      id: 1, 
      username: 'test', 
      email: 'test@test.com', 
      isStaff: true, 
      role: 'administrador'
    ));
  }
}

void main() {
  testWidgets('PagosAdminScreen layout test', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifierMock()),
      ],
    );
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: PagosAdminScreen(),
            ),
          ),
        ),
      ),
    );
    
    // Check for the text
    expect(find.byType(PagosAdminScreen), findsOneWidget);
  });
}
