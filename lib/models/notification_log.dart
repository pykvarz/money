import 'package:hive/hive.dart';

part 'notification_log.g.dart';

@HiveType(typeId: 11)
class NotificationLog {
  @HiveField(0)
  late String packageName;

  @HiveField(1)
  late String text;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  String? parsedAmount;

  @HiveField(4)
  String? parsedKeyword;

  @HiveField(5)
  bool parseSuccess;

  NotificationLog({
    required this.packageName,
    required this.text,
    required this.timestamp,
    this.parsedAmount,
    this.parsedKeyword,
    this.parseSuccess = false,
  });
}
