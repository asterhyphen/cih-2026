import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.name = '',
    this.email = '',
    this.password = '',
    this.error = '',
  });

  final bool isAuthenticated;
  final String name;
  final String email;
  final String password;
  final String error;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  bool register({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.trim().isEmpty || !_validEmail(email) || password.length < 6) {
      state = AuthState(
        name: state.name,
        email: state.email,
        password: state.password,
        error: 'Enter a name, valid email, and 6+ character password.',
      );
      return false;
    }
    state = AuthState(
      isAuthenticated: true,
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
    return true;
  }

  bool signIn({required String email, required String password}) {
    final matchesRegisteredUser =
        email.trim() == state.email && password == state.password;
    final allowFirstLocalLogin = state.email.isEmpty && _validEmail(email);

    if (password.length < 6 ||
        (!matchesRegisteredUser && !allowFirstLocalLogin)) {
      state = AuthState(
        name: state.name,
        email: state.email,
        password: state.password,
        error: 'Check your email and password.',
      );
      return false;
    }

    state = AuthState(
      isAuthenticated: true,
      name: state.name,
      email: email.trim(),
      password: password,
    );
    return true;
  }

  void signOut() => state = AuthState(
    name: state.name,
    email: state.email,
    password: state.password,
  );

  bool _validEmail(String email) => email.contains('@') && email.contains('.');
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
