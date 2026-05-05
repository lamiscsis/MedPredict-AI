import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medpredict_ai_flutter/services/api_service.dart';
import '../models/prediction_model.dart';
import '../models/enums/prediction_result.dart';
import '../models/enums/risk_level.dart';
import 'package:uuid/uuid.dart';

class PredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'predictions';
  final ApiService _apiService = ApiService.instance;
  final _uuid = const Uuid();

  Stream<List<PredictionModel>> streamAllPredictions() {
    return _firestore
        .collection(_collection)
        .orderBy('predictionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PredictionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<PredictionModel>> streamPredictionsForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('predictionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PredictionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<PredictionModel>> getPredictionsForUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('predictionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PredictionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPrediction(PredictionModel prediction) async {
    try {
      if (prediction.predictionId.isEmpty) {
        await _firestore.collection(_collection).add(prediction.toMap());
      } else {
        await _firestore
            .collection(_collection)
            .doc(prediction.predictionId)
            .set(prediction.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePrediction(PredictionModel prediction) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(prediction.predictionId)
          .update(prediction.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePrediction(String predictionId) async {
    try {
      await _firestore.collection(_collection).doc(predictionId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload X-ray image to the API and get AI prediction
  /// 
  /// This method:
  /// 1. Uploads the image to the Flask API
  /// 2. Gets the prediction result with image URL
  /// 3. Saves the prediction to Firebase Firestore (with original localhost URL)
  /// 4. Returns the prediction model
  Future<PredictionModel> uploadXray(String imagePath, String userId) async {
    try {
      // Call the API to get prediction
      final predictionData = await _apiService.uploadXrayForPrediction(imagePath);

      // Parse the response
      final resultString = predictionData['result'] as String;
      final confidence = predictionData['confidence'] as double;
      final rawPrediction = predictionData['raw_prediction'] as double;
      
      // Keep the ORIGINAL imageUrl from API (with localhost) for Firebase
      final imageUrl = predictionData['imageUrl'] as String;
      
      final riskLevelString = predictionData['riskLevel'] as String;

      print('Image URL saved to Firebase: $imageUrl');

      // Map to enum values
      final result = resultString.toLowerCase() == 'pneumonia'
          ? PredictionResult.PNEUMONIA
          : PredictionResult.NORMAL;

      final riskLevel = riskLevelString.toUpperCase() == 'SEVERE'
          ? RiskLevel.SEVERE
          : riskLevelString.toUpperCase() == 'MODERATE'
              ? RiskLevel.MODERATE
              : RiskLevel.MILD;

      // Create prediction model with original imageUrl
      final prediction = PredictionModel(
        predictionId: _uuid.v4(),
        imageId: _uuid.v4(),
        userId: userId,
        result: result,
        confidenceScore: confidence,
        riskLevel: riskLevel,
        predictionDate: DateTime.now(),
        imagePath: imagePath, // Local path
        imageUrl: imageUrl, // Original URL from API (with localhost)
      );

      // Save to Firebase Firestore
      await addPrediction(prediction);

      return prediction;
    } catch (e) {
      throw Exception('Failed to upload X-ray: $e');
    }
  }
}

// Provider for PredictionService
final predictionServiceProvider =
    Provider<PredictionService>((ref) => PredictionService());

// StreamProvider for all predictions (admin use)
final allPredictionsStreamProvider = StreamProvider<List<PredictionModel>>((ref) {
  final service = ref.watch(predictionServiceProvider);
  return service.streamAllPredictions();
});

// StreamProvider.family for user-specific predictions
final userPredictionsStreamProvider = StreamProvider.autoDispose
    .family<List<PredictionModel>, String>((ref, userId) {
  final service = ref.watch(predictionServiceProvider);
  return service.streamPredictionsForUser(userId);
});

// StreamProvider for the latest (most recent) prediction of a user
final latestUserPredictionProvider = StreamProvider.autoDispose
    .family<PredictionModel?, String>((ref, userId) {
  final service = ref.watch(predictionServiceProvider);
  return service.streamPredictionsForUser(userId).map(
        (predictions) => predictions.isNotEmpty ? predictions.first : null,
      );
});
