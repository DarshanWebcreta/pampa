import 'package:pampa/core/values/urls.dart';

class CategoryModel {
  final int id;
  final String categoryName;
  final String? icon;
  final String status;
  final String createdAt;
  final String updatedAt;

  const CategoryModel({
    required this.id,
    required this.categoryName,
    this.icon,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawIcon = json['icon']?.toString();

    return CategoryModel(
      id: json['id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      icon: _resolveIconUrl(rawIcon),
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  static String? _resolveIconUrl(String? icon) {
    if (icon == null) return null;

    final trimmed = icon.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '${ApiStrings.imageUrl}$trimmed';
    }

    return '${ApiStrings.imageUrl}/$trimmed';
  }
}
