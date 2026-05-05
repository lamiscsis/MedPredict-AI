import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_tip_model.dart';

class HealthTipsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'health_tips';

  Stream<List<HealthTipModel>> streamHealthTips() {
    return _firestore
        .collection(_collection)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthTipModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<HealthTipModel>> getHealthTips() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => HealthTipModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addHealthTip(HealthTipModel tip) async {
    try {
      // If tipId is empty, Firestore will auto-generate it.
      // Then we can update the ID to mirror it, or simply use add()
      if (tip.tipId.isEmpty) {
        await _firestore.collection(_collection).add(tip.toMap());
      } else {
        await _firestore
            .collection(_collection)
            .doc(tip.tipId)
            .set(tip.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHealthTip(HealthTipModel tip) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(tip.tipId)
          .update(tip.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHealthTip(String tipId) async {
    try {
      await _firestore.collection(_collection).doc(tipId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

final healthTipsServiceProvider =
    Provider<HealthTipsService>((ref) => HealthTipsService());
