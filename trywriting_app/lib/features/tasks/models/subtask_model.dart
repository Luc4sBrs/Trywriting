class SubtaskModel {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;

  SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: json['id'],
      taskId: json['task_id'],
      title: json['title'],
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
    };
  }
}