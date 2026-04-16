import 'package:pampa/core/values/urls.dart';

class CategoryModel {
  final int id;
  final String categoryName;
  final String? tag;
  final String? icon;
  final String status;
  final String createdAt;
  final String updatedAt;

  const CategoryModel({
    required this.id,
    required this.categoryName,
    this.tag,
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
      tag: json['tag']?.toString(),
      icon: _resolveIconUrl(rawIcon),
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  CategoryModel copyWith({
    int? id,
    String? categoryName,
    String? tag,
    String? icon,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      tag: tag ?? this.tag,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
