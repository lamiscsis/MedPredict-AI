import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medical_history_model.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'medical_history';

  Stream<List<MedicalHistoryModel>> streamUserHistory(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('recordDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicalHistoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<MedicalHistoryModel>> getHistoryForUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('recordDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MedicalHistoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addHistoryRecord(MedicalHistoryModel record) async {
    try {
      if (record.historyId.isEmpty) {
        await _firestore.collection(_collection).add(record.toMap());
      } else {
        await _firestore
            .collection(_collection)
            .doc(record.historyId)
            .set(record.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHistoryRecord(MedicalHistoryModel record) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(record.historyId)
          .update(record.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHistoryRecord(String historyId) async {
    try {
      await _firestore.collection(_collection).doc(historyId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());
