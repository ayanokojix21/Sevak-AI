import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<TaskEntity>> getMyTasksStream(String volunteerUid) {
    return _db
        .collection('needs')
        .where('assignedTo', isEqualTo: volunteerUid)
        .where('status', whereIn: ['ASSIGNED', 'IN_PROGRESS'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return TaskEntity(
                id: doc.id,
                description: data['rawText'] as String? ?? '',
                imageUrl: data['imageUrl'] as String?,
                location: data['location'] as String? ?? '',
                lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
                lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
                needType: data['needType'] as String? ?? 'OTHER',
                urgencyScore: (data['urgencyScore'] as num?)?.toInt() ?? 0,
                status: data['status'] as String? ?? 'ASSIGNED',
                ngoId: data['ngoId'] as String? ?? '',
                matchReason: data['matchReason'] as String?,
                crossNgoTaskId: data['crossNgoTaskId'] as String?,
                sourceNgoName: data['sourceNgoName'] as String?,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  @override
  Future<void> updateTaskStatus({
    required String taskId,
    required String newStatus,
    required String volunteerUid,
  }) async {
    await _db.runTransaction((tx) async {
      final needRef = _db.collection('needs').doc(taskId);
      final needSnap = await tx.get(needRef);
      if (!needSnap.exists) return;

      tx.update(needRef, {'status': newStatus});

      // When completed, decrement volunteer's activeTasks
      if (newStatus == 'COMPLETED') {
        final volRef = _db.collection('volunteers').doc(volunteerUid);
        final volSnap = await tx.get(volRef);
        if (volSnap.exists) {
          final current = (volSnap.data()?['activeTasks'] as num?)?.toInt() ?? 0;
          tx.update(volRef, {'activeTasks': (current - 1).clamp(0, 999)});
        }
      }
    });
  }
}
