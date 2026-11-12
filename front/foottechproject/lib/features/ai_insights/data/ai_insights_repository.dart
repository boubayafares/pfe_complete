import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class PlayerTrend {
  const PlayerTrend({
    required this.direction,
    required this.slopePerMonth,
    required this.rSquared,
    required this.dataPointsUsed,
  });

  factory PlayerTrend.fromJson(Map<String, dynamic> json) => PlayerTrend(
    direction: json['direction'] as String,
    slopePerMonth: (json['slopePerMonth'] as num).toDouble(),
    rSquared: (json['rSquared'] as num).toDouble(),
    dataPointsUsed: (json['dataPointsUsed'] as num).toInt(),
  );

  final String direction;
  final double slopePerMonth;
  final double rSquared;
  final int dataPointsUsed;
}

class ExpertProjectModel {
  const ExpertProjectModel({
    required this.name,
    required this.modelType,
    required this.maturityScore,
    required this.signals,
    required this.capabilities,
    required this.recommendations,
  });

  factory ExpertProjectModel.fromJson(Map<String, dynamic> json) {
    return ExpertProjectModel(
      name: json['name'] as String,
      modelType: json['modelType'] as String,
      maturityScore: (json['maturityScore'] as num).toDouble(),
      signals: Map<String, dynamic>.from(json['signals'] as Map),
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String name;
  final String modelType;
  final double maturityScore;
  final Map<String, dynamic> signals;
  final List<Map<String, dynamic>> capabilities;
  final List<String> recommendations;

  int get maturityPercent => maturityScore.round();
  double get maturityProgress =>
      (maturityScore / 100).clamp(0.0, 1.0).toDouble();
}

class AiInsightsRepository {
  const AiInsightsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<PlayerTrend> getPlayerTrend(int playerId) async {
    final body = await _api.get(
      '${ApiConstants.aiInsights}/players/$playerId/trend',
    );
    return PlayerTrend.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ExpertProjectModel> getExpertProjectModel() async {
    final body = await _api.get(
      '${ApiConstants.aiInsights}/expert-project-model',
    );
    return ExpertProjectModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
