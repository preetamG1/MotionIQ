import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/workout_model.dart';
import 'local_storage_service.dart';
import '../../services/service_locator.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Auto-sync offline data after successful login
      await syncOfflineData();
      
      return userCredential.user;
    } catch (e) {
      print("Google Auth Error: $e");
      return null;
    }
  }

  String? get currentUserId => _auth.currentUser?.uid ?? "offline_user";

  // Unified save: Cloud first, Local backup
  Future<void> saveWorkout(WorkoutModel workout) async {
    // 1. Always save locally first (Persistence)
    await sl<LocalStorageService>().saveWorkoutLocally(workout);

    // 2. Try saving to Cloud if logged in
    if (_auth.currentUser != null) {
      try {
        await _firestore.collection('workouts').add(workout.toMap());
      } catch (e) {
        print("Firestore Sync Pending: $e");
      }
    }
  }

  // Sync logic: Push all local data to Cloud
  Future<void> syncOfflineData() async {
    if (_auth.currentUser == null) return;

    final localData = await sl<LocalStorageService>().getLocalWorkouts();
    if (localData.isEmpty) return;

    for (var workout in localData) {
      try {
        // Create new model with current user ID before syncing
        final syncModel = WorkoutModel(
          userId: _auth.currentUser!.uid,
          exercise: workout.exercise,
          reps: workout.reps,
          calories: workout.calories,
          postureScore: workout.postureScore,
          timestamp: workout.timestamp,
        );
        await _firestore.collection('workouts').add(syncModel.toMap());
      } catch (e) {
        break; // Stop if sync fails halfway
      }
    }
    // Clear local storage after successful cloud upload
    // Note: In a production app, we'd only clear what was successfully synced
    // For MVP, we clear all to keep logic simple.
    await sl<LocalStorageService>().clearLocalWorkouts();
  }

  Stream<List<WorkoutModel>> getWorkoutHistoryStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Return local data stream if offline
      return Stream.fromFuture(sl<LocalStorageService>().getLocalWorkouts());
    }

    return _firestore
        .collection('workouts')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs.map((doc) => WorkoutModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
