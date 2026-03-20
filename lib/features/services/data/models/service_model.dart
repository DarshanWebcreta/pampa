import 'package:pampa/features/categories/data/models/category_model.dart';

class ServiceModel {
  final int id;
  final int categoryId;
  final String serviceName;
  final String price;
  final String image;
  final int duration;
  final double deposit;
  final double priorityFee;
  final String? description;
  final double serviceCommission;
  final String status;
  final String createdAt;
  final String updatedAt;
  final CategoryModel? category;

  const ServiceModel({
    required this.id,
    required this.categoryId,
    required this.serviceName,
    required this.price,
    required this.image,
    required this.duration,
    required this.deposit,
    required this.priorityFee,
    this.description,
    required this.serviceCommission,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      serviceName: json['service_name'] ?? '',
      price: json['price'] ?? '0.00',
      image: json['image_url'] ?? '',
      duration: json['duration'] ?? 0,
      deposit: _toDouble(json['deposit']),
      priorityFee: _toDouble(json['priority_fee']),
      description: json['description'],
      serviceCommission: _toDouble(json['service_commission']),
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  /// Returns price as "\$10.00" formatted string.
  String get formattedPrice {
    final val = priceAsDouble;
    if (val == val.truncateToDouble()) {
      return '\$${val.toInt()}';
    }
    return '\$${val.toStringAsFixed(2)}';
  }

  /// Returns duration as "60 min" string.
  String get formattedDuration => '$duration min';

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
