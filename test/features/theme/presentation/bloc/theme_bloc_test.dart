import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:ecg/features/theme/presentation/bloc/theme_bloc.dart';
import 'package:ecg/features/theme/presentation/bloc/theme_event.dart';
import 'package:ecg/features/theme/presentation/bloc/theme_state.dart';

void main() {
  group('ThemeBloc', () {
    late ThemeBloc themeBloc;

    setUp(() {
      themeBloc = ThemeBloc();
    });

    tearDown(() {
      themeBloc.close();
    });

    test('initial state is ThemeInitial', () {
      expect(themeBloc.state, isA<ThemeInitial>());
    });

    blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeLoaded] when ThemeInitialized is added',
      build: () => ThemeBloc(),
      act: (bloc) => bloc.add(const ThemeInitialized()),
      expect: () => [isA<ThemeLoaded>()],
    );
  });
}
