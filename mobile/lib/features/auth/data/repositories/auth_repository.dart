import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _storageService;

  AuthRepository(this._dioClient, this._storageService);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final access = data['access'] as String;
    final refresh = data['refresh'] as String?;

    await _storageService.saveTokens(access: access, refresh: refresh);

    // Fast-path: return user embedded directly in the login response
    if (data['user'] != null && data['user'] is Map<String, dynamic>) {
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await saveCachedUser(user);
      return user;
    }

    final user = await getMe();
    await saveCachedUser(user);
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? department,
    String? institution,
  }) async {
    await _dioClient.post(
      ApiEndpoints.register,
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        if (department != null && department.isNotEmpty) 'department': department.trim(),
        if (institution != null && institution.isNotEmpty) 'institution': institution.trim(),
      },
    );

    // Auto login after registration
    return await login(email: email, password: password);
  }

  Future<UserModel> getMe() async {
    final response = await _dioClient.get(ApiEndpoints.me);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await saveCachedUser(user);
    return user;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dioClient.patch(ApiEndpoints.me, data: data);
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    await saveCachedUser(user);
    return user;
  }

  Future<void> logout() async {
    await _storageService.clearTokens();
  }

  Future<bool> hasValidToken() async {
    final token = await _storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveCachedUser(UserModel user) async {
    try {
      await _storageService.saveCachedUserJson(jsonEncode(user.toJson()));
    } catch (_) {}
  }

  UserModel? getCachedUser() {
    try {
      final jsonStr = _storageService.getCachedUserJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
