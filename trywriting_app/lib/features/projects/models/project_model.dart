class ProjectModel {
  final String id;
  final String title;
  final String? description;
  final String ownerId;
  final DateTime createdAt;
  final String? iconName; // Add esta linha

  ProjectModel({
    required this.id,
    required this.title,
    this.description,
    required this.ownerId,
    required this.createdAt,
    this.iconName, // Add esta linha
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      iconName: json['icon_name'], // Nome da coluna no banco (ex: Supabase)
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'owner_id': ownerId};
  }
}
