import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ecg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ecg/features/auth/presentation/bloc/auth_state.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when AuthCheckRequested is added and no user',
      build: () => AuthBloc(),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });
}
