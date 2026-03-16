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
    return CategoryModel(
      id: json['id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      icon: json['icon'],
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isActive => status.toLowerCase() == 'active';
}
