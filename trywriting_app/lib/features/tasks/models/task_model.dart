class TaskModel {
  final String id;
  final String projectId;
  final String columnId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? priority; // "Baixa", "Média", "Alta"
  final String? assignedTo;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.columnId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.assignedTo,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      projectId: json['project_id'],
      columnId: json['column_id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] ?? 'Média',
      assignedTo: json['assigned_to'],
    );
  }
}