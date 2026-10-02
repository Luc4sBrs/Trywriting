class ColumnModel {
  final String id;
  final String projectId;
  final String title;
  final int position;
  final DateTime createdAt;

  ColumnModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.position,
    required this.createdAt,
  });

  factory ColumnModel.fromJson(Map<String, dynamic> json) {
    return ColumnModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'position': position,
    };
  }
}
