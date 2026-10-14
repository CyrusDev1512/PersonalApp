import 'json_utils.dart';
import 'level.dart';

/// Một cảnh báo trong lịch sử (`kind` ∈ tx, floor, safe, budget, digest, account, health, info).
class Alert {
  const Alert({
    required this.id,
    required this.kind,
    required this.level,
    required this.title,
    required this.message,
    this.createdAt,
    this.read = false,
    this.transactionId,
    this.goalId,
  });

  final int id;
  final DateTime? createdAt;
  final String kind;
  final Level level;
  final String title;
  final String message;
  final bool read;
  final int? transactionId;
  final int? goalId;

  Alert copyWith({bool? read}) => Alert(
    id: id,
    createdAt: createdAt,
    kind: kind,
    level: level,
    title: title,
    message: message,
    read: read ?? this.read,
    transactionId: transactionId,
    goalId: goalId,
  );

  factory Alert.fromJson(JsonMap json) => Alert(
    id: asInt(json['id']),
    createdAt: asDateTime(json['created_at']),
    kind: asString(json['kind'], 'info'),
    level: Level.parse(json['level']),
    title: asString(json['title']),
    message: asString(json['message']),
    read: asBool(json['read']),
    transactionId: asIntOrNull(json['transaction_id']),
    goalId: asIntOrNull(json['goal_id']),
  );
}
