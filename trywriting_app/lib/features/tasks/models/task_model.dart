class TaskModel {
  final String id;
  final String projectId;
  final String columnId;
  final String title;
  final String userId;
  final String? description;
  final DateTime? dueDate;
  final String? priority; // "Baixa", "Média", "Alta"
  final String? assignedTo;
  final String? label; // ADICIONADO
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.columnId,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.assignedTo,
    this.label, // ADICIONADO
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      projectId: json['project_id'],
      columnId: json['column_id'],
      userId: json['user_id'] as String,
      title: json['title'],
      description: json['description'],
      label: json['label'] as String?, // ADICIONADO
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] ?? 'Média',
      assignedTo: json['assigned_to'],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'column_id': columnId,
      'user_id': userId,
      'title': title,
      'description': description,
      'label': label, // ADICIONADO
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}