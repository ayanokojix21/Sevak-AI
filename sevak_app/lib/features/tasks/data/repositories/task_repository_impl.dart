import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';

import '../../data/models/impact_story_model.dart';
import '../../../../core/constants/app_constants.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<TaskEntity>> getMyTasksStream(String volunteerUid) {
    return _db
        .collection(AppConstants.needsCollection)
        .where('assignedVolunteerIds', arrayContains: volunteerUid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.where((doc) {
            final status = doc.data()['status'] as String? ?? '';
            return status == 'ASSIGNED' || status == 'IN_PROGRESS';
          }).toList();
          
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          
          return docs.map((doc) {
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
            }).toList();
        });
  }

  @override
  Future<void> updateTaskStatus({
    required String taskId,
    required String newStatus,
    required String volunteerUid,
  }) async {
    await _db.runTransaction((tx) async {
      final needRef = _db.collection(AppConstants.needsCollection).doc(taskId);

      final needSnap = await tx.get(needRef);
      if (!needSnap.exists) return;

      DocumentSnapshot? volSnap;
      final volRef = _db.collection(AppConstants.volunteersCollection).doc(volunteerUid);

      // For COMPLETED, we need all assigned volunteer snapshots
      List<String> assignedIds = [];
      Map<String, DocumentSnapshot> allVolSnaps = {};

      if (newStatus == 'COMPLETED') {
        assignedIds = List<String>.from(needSnap.data()?['assignedVolunteerIds'] as Iterable? ?? []);
        if (assignedIds.isEmpty) {
          final assignedTo = needSnap.data()?['assignedTo'] as String?;
          if (assignedTo != null) assignedIds.add(assignedTo);
        }
        for (final uid in assignedIds) {
          final ref = _db.collection(AppConstants.volunteersCollection).doc(uid);
          allVolSnaps[uid] = await tx.get(ref);
        }
      } else if (newStatus == 'SCORED') {
        // Decline: only need to read the declining volunteer
        volSnap = await tx.get(volRef);
      }

      final updates = <String, dynamic>{'status': newStatus};

      if (newStatus == 'SCORED') {
        // Remove this volunteer from assigned list and record rejection
        updates['assignedVolunteerIds'] = FieldValue.arrayRemove([volunteerUid]);
        updates['rejectedBy'] = FieldValue.arrayUnion([volunteerUid]);

        // Decrement active tasks for the declining volunteer
        if (volSnap != null && volSnap.exists) {
          final current = (volSnap.data() as Map<String, dynamic>?)?['activeTasks'];
          final count = (current as num?)?.toInt() ?? 0;
          tx.update(volRef, {'activeTasks': (count - 1).clamp(0, 999)});
        }
      }

      tx.update(needRef, updates);

      if (newStatus == 'COMPLETED') {
        for (final uid in assignedIds) {
          final snap = allVolSnaps[uid];
          if (snap != null && snap.exists) {
            final ref = _db.collection(AppConstants.volunteersCollection).doc(uid);
            final current = (snap.data() as Map<String, dynamic>?)?['activeTasks'];
            final count = (current as num?)?.toInt() ?? 0;
            tx.update(ref, {'activeTasks': (count - 1).clamp(0, 999)});
          }
        }
      }
    });
  }


  @override
  Future<void> saveImpactStory(ImpactStoryModel story) async {
    await _db.collection(AppConstants.impactStoriesCollection).add(story.toJson());
  }
}
