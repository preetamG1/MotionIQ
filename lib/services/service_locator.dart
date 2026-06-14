import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/firebase_service.dart';
import '../core/services/pose_service.dart';
import '../core/services/exercise_service.dart';
import '../core/services/local_storage_service.dart';
import 'tts_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Services
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
  sl.registerLazySingleton<PoseService>(() => PoseService());
  sl.registerLazySingleton<ExerciseService>(() => ExerciseService());
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService(sl()));
  sl.registerLazySingleton<TtsService>(() => TtsService());
}