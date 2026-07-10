import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/progress/domain/repositories/progress_repository.dart';
import '../features/progress/data/repositories/progress_repository_impl.dart';
import '../features/progress/presentation/bloc/progress_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. External dependencies
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  final dio = Dio();
  dio.options = BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException err, handler) async {
        if (err.response?.statusCode == 401) {
          // Clear session data on 401 Unauthorized
          await secureStorage.delete(key: 'auth_token');
          // Reset AuthBloc state to Unauthenticated
          sl<AuthBloc>().add(SignOutPressed());
        }
        return handler.next(err);
      },
    ),
  );
  
  sl.registerLazySingleton<Dio>(() => dio);

  // 2. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<Dio>(), sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(sl<Dio>()),
  );

  // 3. Blocs / Cubits
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(sl<AuthRepository>()),
  );
  sl.registerFactory<ProgressBloc>(
    () => ProgressBloc(sl<ProgressRepository>()),
  );
}
