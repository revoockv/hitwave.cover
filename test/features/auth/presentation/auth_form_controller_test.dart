import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result_state.dart';
import 'package:hitwave.cover/features/auth/presentation/controllers/auth_form_controller.dart';

void main() {
  late AuthFormController authFormController;

  setUp(() => authFormController = AuthFormController());

  tearDown(() => authFormController.dispose());

  test('empty fields are reported', () {
    expect(authFormController.hasEmptyFields, isTrue);

    authFormController.emailController.text = 'a@b.c';
    expect(authFormController.hasEmptyFields, isTrue);

    authFormController.passwordController.text = 'secret';
    expect(authFormController.hasEmptyFields, isFalse);
  });

  test('the email is trimmed, the password is kept as typed', () {
    authFormController.emailController.text = '  a@b.c ';
    authFormController.passwordController.text = ' secret ';

    expect(authFormController.email, 'a@b.c');
    expect(authFormController.password, ' secret ');
  });

  test('toggling the mode switches to sign-up and clears the last error', () {
    authFormController.submittingStateController.value = const ResultState<void>.failure('taken');

    authFormController.toggleMode();

    expect(authFormController.signUpModeController.value, isTrue);
    expect(authFormController.submittingStateController.value.isIdle, isTrue);
  });

  test('the password visibility toggles', () {
    expect(authFormController.passwordHiddenController.value, isTrue);

    authFormController.togglePasswordVisibility();

    expect(authFormController.passwordHiddenController.value, isFalse);
  });
}
