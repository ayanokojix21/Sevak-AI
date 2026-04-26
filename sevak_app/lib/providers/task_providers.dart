import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../features/location/data/location_service.dart';
import '../features/tasks/data/repositories/task_repository_impl.dart';
import '../features/tasks/domain/entities/task_entity.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/needs/domain/entities/need_entity.dart';
import '../features/needs/data/datasources/ai_datasource.dart';
import '../features/matching/domain/usecases/match_volunteer_usecase.dart';
import '../features/tasks/data/models/impact_story_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl();
});

final myTasksStreamProvider = StreamProvider<List<TaskEntity>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).getMyTasksStream(uid);
});

final taskControllerProvider =
    StateNotifierProvider<TaskController, AsyncValue<void>>((ref) {
  return TaskController(ref.watch(taskRepositoryProvider));
});

class TaskController extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;

  TaskController(this._repository) : super(const AsyncValue.data(null));

  Future<void> updateStatus(String taskId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _repository.updateTaskStatus(
        taskId: taskId,
        newStatus: newStatus,
        volunteerUid: uid,
      );
      
      if (uid.isNotEmpty) {
        if (newStatus == 'IN_PROGRESS') {
          // Force an immediate update, then start continuous streaming
          await LocationService().updateVolunteerLocation(uid, force: true);
          LocationService().startLiveTracking(uid);
        } else if (newStatus == 'COMPLETED' || newStatus == 'DECLINED' || newStatus == 'FAILED') {
          LocationService().stopLiveTracking();
        }
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> declineTask(TaskEntity task, MatchVolunteerUseCase matchUseCase) async {
    state = const AsyncValue.loading();
    LocationService().stopLiveTracking(); // Stop if declining
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _repository.updateTaskStatus(
        taskId: task.id,
        newStatus: 'SCORED',
        volunteerUid: uid,
      );
      
      // Reconstruct NeedEntity to re-run matching
      final needToRematch = NeedEntity(
        id: task.id,
        rawText: task.description,
        location: task.location,
        lat: task.lat,
        lng: task.lng,
        needType: task.needType,
        urgencyScore: task.urgencyScore,
        urgencyReason: task.matchReason ?? '',
        peopleAffected: 0,
        status: 'SCORED', // Status was just reset to SCORED
        submittedBy: 'unknown',
        ngoId: task.ngoId,
        createdAt: task.createdAt,
      );

      // Fire and forget matching in the background
      matchUseCase.call(needToRematch).catchError((Object e) {
        debugPrint('[TaskController] Failed to rematch task: $e');
        return '';
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeTaskWithStory({
    required TaskEntity task,
    required String completionNotes,
    required AiDatasource ai,
    List<int>? successImageBytes,
    String? afterImageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // 1. Generate Story
      final aiResult = await ai.generateImpactStory(
        task.description,
        completionNotes,
        successImageBytes,
      );

      // 2. Save Story
      final story = ImpactStoryModel(
        id: const Uuid().v4(),
        needId: task.id,
        ngoId: task.ngoId,
        headline: aiResult['headline'] as String? ?? 'Task Completed',
        story: aiResult['story'] as String? ?? 'A task was completed by our dedicated volunteer.',
        beforeImageUrl: task.imageUrl,
        afterImageUrl: afterImageUrl,
        createdAt: DateTime.now(),
      );
      await _repository.saveImpactStory(story);

      // 3. Update Status
      await _repository.updateTaskStatus(
        taskId: task.id,
        newStatus: 'COMPLETED',
        volunteerUid: uid,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
