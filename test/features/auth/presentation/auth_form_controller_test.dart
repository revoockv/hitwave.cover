import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/core/domain/entities/result_state.dart';
import 'package:hitwave.cover/features/auth/presentation/controllers/auth_form_controller.dart';

void main() {
  late List<String> calls;
  late Result<void> nextResult;
  late AuthFormController controller;

  Future<Result<void>> signIn({required String email, required String password}) async {
    calls.add('in:$email:$password');
    return nextResult;
  }

  Future<Result<void>> signUp({required String email, required String password}) async {
    calls.add('up:$email:$password');
    return nextResult;
  }

  setUp(() {
    calls = <String>[];
    nextResult = Result.ok;
    controller = AuthFormController(signIn: signIn, signUp: signUp);
  });

  tearDown(() => controller.dispose());

  test('empty fields fail without calling an action', () async {
    await controller.submit();

    expect(calls, isEmpty);
    expect(controller.value, isA<FailureResultState<void>>());
  });

  test('signs in with the trimmed email and records success', () async {
    controller.email.text = '  a@b.c ';
    controller.password.text = 'secret';

    await controller.submit();

    expect(calls, <String>['in:a@b.c:secret']);
    expect(controller.value.isSuccess, isTrue);
  });

  test('sign-up mode runs sign-up and keeps its failure message', () async {
    nextResult = const Result.failure('taken');
    controller.toggleMode();
    controller.email.text = 'a@b.c';
    controller.password.text = 'secret';

    await controller.submit();

    expect(calls, <String>['up:a@b.c:secret']);
    expect((controller.value as FailureResultState<void>).message, 'taken');
  });

  test('toggling the mode clears the last error', () async {
    await controller.submit();
    controller.toggleMode();

    expect(controller.value.isIdle, isTrue);
    expect(controller.isSignUp.value, isTrue);
  });
}
