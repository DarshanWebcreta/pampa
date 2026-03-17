class TimeSlotModel {
  final String time;     // "09:00"
  final String endTime;  // "09:10"
  final bool available;

  const TimeSlotModel({
    required this.time,
    required this.endTime,
    required this.available,
  });

  /// Converts "09:00" → "9:00 AM", "13:00" → "1:00 PM"
  String get displayTime {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      time: json['time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      available: json['available'] as bool? ?? false,
    );
  }
}
