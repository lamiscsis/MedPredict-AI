import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.userId)
          .set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.userId)
          .update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }
}

// Provider for UserService
final userServiceProvider = Provider<UserService>((ref) => UserService());

// StreamProvider for all users (admin use)
final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(userServiceProvider);
  return service.streamAllUsers();
});
