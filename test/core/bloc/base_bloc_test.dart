import 'package:flutter_test/flutter_test.dart';
import 'package:ecg/core/bloc/base_bloc.dart';

void main() {
  group('BaseState', () {
    test('InitialState is a BaseState', () {
      expect(const InitialState(), isA<BaseState>());
    });

    test('LoadingAppState is loading', () {
      expect(const LoadingAppState().isLoading, true);
    });

    test('ErrorAppState has error message', () {
      const errorState = ErrorAppState('Test error');
      expect(errorState.errorMessage, 'Test error');
      expect(errorState.hasError, true);
    });
  });
}
