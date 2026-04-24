import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/tasks/data/repositories/task_repository_impl.dart';
import '../features/tasks/domain/entities/task_entity.dart';
import '../features/tasks/domain/repositories/task_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl();
});

// ── My Tasks Stream ───────────────────────────────────────────────────────────
final myTasksStreamProvider = StreamProvider<List<TaskEntity>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).getMyTasksStream(uid);
});

// ── Controller ────────────────────────────────────────────────────────────────
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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
