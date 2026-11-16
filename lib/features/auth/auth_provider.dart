import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class UserData {
  final String id;
  final String name;
  final String email;

  UserData({required this.id, required this.name, required this.email});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class AuthState {
  final bool isLoading;
  final UserData? user;
  final String? token;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    bool? isLoading,
    UserData? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();

  AuthNotifier() : super(AuthState(isLoading: true)) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final response = await _apiClient.get('/user');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserData.fromJson(data);
        state = state.copyWith(isLoading: false, user: user, token: token);
      } else {
        await _apiClient.clearToken();
        state = state.copyWith(isLoading: false, token: null, user: null);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = UserData.fromJson(data['user']);

        await _apiClient.saveToken(token);
        state = state.copyWith(isLoading: false, user: user, token: token);
        return true;
      } else {
        final err = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: err['message'] ?? 'Login gagal. Periksa kembali email & password.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Koneksi gagal: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String confirmation) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmation,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = UserData.fromJson(data['user']);

        await _apiClient.saveToken(token);
        state = state.copyWith(isLoading: false, user: user, token: token);
        return true;
      } else {
        final err = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: err['message'] ?? 'Pendaftaran gagal.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Koneksi gagal: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout', {});
    } catch (_) {}
    await _apiClient.clearToken();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
