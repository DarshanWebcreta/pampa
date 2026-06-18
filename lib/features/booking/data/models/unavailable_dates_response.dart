class UnavailableDatesResponse {
  final bool status;
  final String message;
  final List<String> unavailableDates;

  const UnavailableDatesResponse({
    required this.status,
    required this.message,
    required this.unavailableDates,
  });

  factory UnavailableDatesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<String> datesList = [];

    if (data is Map<String, dynamic>) {
      final rawDates = data['unavailable_dates'];
      if (rawDates is List) {
        datesList = rawDates.map((e) => e.toString()).toList();
      }
    }

    return UnavailableDatesResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      unavailableDates: datesList,
    );
  }
}
