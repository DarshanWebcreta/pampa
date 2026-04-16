class SlotModel {
  final String time;
  final String endTime;
  final bool available;
  final String? label;

  const SlotModel({
    required this.time,
    required this.endTime,
    required this.available,
    this.label,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      time: json['time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      available: json['available'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'end_time': endTime,
      'available': available,
    };
  }
}
