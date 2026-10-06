import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isInitialCheckDone;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isInitialCheckDone = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isInitialCheckDone,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialCheckDone: isInitialCheckDone ?? this.isInitialCheckDone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final hasToken = await _repository.hasValidToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!hasToken) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          isInitialCheckDone: true,
        );
        return;
      }

      final user = await _repository.getMe().timeout(
        const Duration(seconds: 4),
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        isInitialCheckDone: true,
      );
    } catch (_) {
      await _repository.logout();
      state = state.copyWith(
        user: null,
        isLoading: false,
        isAuthenticated: false,
        isInitialCheckDone: true,
      );
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? department,
    String? institution,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        department: department,
        institution: institution,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(
      user: null,
      isAuthenticated: false,
      isInitialCheckDone: true,
    );
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repository.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = await _repository.updateProfile(data);
      state = state.copyWith(user: user);
      return true;
    } catch (_) {
      if (state.user != null) {
        final updated = state.user!.copyWith(
          fullName: data['full_name'] as String?,
          department: data['department'] as String?,
          currentTrimester: data['current_trimester'] as String?,
          currentGpa: (data['current_gpa'] != null) ? double.tryParse('${data['current_gpa']}') : null,
          targetGpa: (data['target_gpa'] != null) ? double.tryParse('${data['target_gpa']}') : null,
          targetDailyMinutes: data['target_daily_minutes'] as int?,
          isOnboarded: data['is_onboarded'] as bool? ?? true,
        );
        state = state.copyWith(user: updated);
        return true;
      }
      return false;
    }
  }

  void restoreUser(UserModel user) {
    state = state.copyWith(user: user, isAuthenticated: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
