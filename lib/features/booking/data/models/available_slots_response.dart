import 'package:pampa/features/booking/data/models/slot_model.dart';

class AvailableSlotsResponse {
  final bool status;
  final String message;
  final int serviceDuration;
  final List<SlotModel> slots;

  const AvailableSlotsResponse({
    required this.status,
    required this.message,
    required this.serviceDuration,
    required this.slots,
  });

  factory AvailableSlotsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<SlotModel> slotsList = [];

    if (data is Map<String, dynamic>) {
      // Prefer 'available_slots' if present as it's often the filtered list
      final rawSlots = data['available_slots'] ?? data['slots'];
      if (rawSlots is List) {
        slotsList = rawSlots
            .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (json['slots'] is List) {
      // Fallback for different API structures
      slotsList = (json['slots'] as List)
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AvailableSlotsResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      serviceDuration: (data is Map<String, dynamic> ? data['service_duration'] as int? : null) ?? 0,
      slots: slotsList,
    );
  }
}
