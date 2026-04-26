import '../entities/task_entity.dart';
import '../../data/models/impact_story_model.dart';

abstract class TaskRepository {
  /// Real-time stream of tasks assigned to the current volunteer.
  Stream<List<TaskEntity>> getMyTasksStream(String volunteerUid);

  /// Update a task's status (IN_PROGRESS or COMPLETED).
  Future<void> updateTaskStatus({
    required String taskId,
    required String newStatus,
    required String volunteerUid,
  });

  /// Save an AI-generated impact story.
  Future<void> saveImpactStory(ImpactStoryModel story);
}
