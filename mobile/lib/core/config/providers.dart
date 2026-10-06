import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

// Must be overridden in ProviderScope after SharedPreferences.getInstance()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secure = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(secure, prefs);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return DioClient(storageService: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(dioClient, storage);
});
