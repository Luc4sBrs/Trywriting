import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trywriting_app/features/tasks/models/subtask_model.dart';
import 'package:trywriting_app/features/tasks/models/task_comment_model.dart';
import '../models/column_model.dart';
import '../models/task_model.dart';

class TaskController {
  final _supabase = Supabase.instance.client;

  // --- COLUNAS ---

  // Busca as colunas do projeto ordenadas pela posição
  Future<List<ColumnModel>> fetchColumns(String projectId) async {
    final response = await _supabase
        .from('columns')
        .select()
        .eq('project_id', projectId)
        .order('position', ascending: true);

    return (response as List)
        .map((json) => ColumnModel.fromJson(json))
        .toList();
  }

  // Cria as colunas padrão caso o projeto seja novo
  Future<void> createDefaultColumns(String projectId) async {
    final existingColumns = await fetchColumns(projectId);
    if (existingColumns.isNotEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final defaultColumns = [
      {'project_id': projectId, 'user_id': user.id, 'title': 'A Fazer', 'position': 0},
      {'project_id': projectId, 'user_id': user.id, 'title': 'Em Progresso', 'position': 1},
      {'project_id': projectId, 'user_id': user.id, 'title': 'Concluído', 'position': 2},
    ];

    await _supabase.from('columns').insert(defaultColumns);
  }

  // Adiciona uma nova coluna ao projeto
  Future<void> createColumn(String projectId, String title) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // Obtém o número total de colunas para definir a próxima posição
    final existingColumns = await fetchColumns(projectId);
    final nextPosition = existingColumns.length;

    await _supabase.from('columns').insert({
      'project_id': projectId,
      'user_id': user.id,
      'title': title,
      'position': nextPosition,
    });
  }

  // Renomeia uma coluna existente
  Future<void> updateColumnTitle(String columnId, String newTitle) async {
    await _supabase
        .from('columns')
        .update({'title': newTitle})
        .eq('id', columnId);
  }

  // Elimina uma coluna
  Future<void> deleteColumn(String columnId) async {
    await _supabase.from('columns').delete().eq('id', columnId);
  }

  // --- TAREFAS ---

  // Escuta as tarefas do projeto em tempo real usando Supabase Realtime Stream
  Stream<List<TaskModel>> getTasksStream(String projectId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: true)
        .map((listOfMaps) =>
            listOfMaps.map((json) => TaskModel.fromJson(json)).toList());
  }

  // Cria uma nova tarefa atribuindo o user_id do usuário atual
  Future<void> createTask({
    required String projectId,
    required String columnId,
    required String title,
    String? description,
    String? label,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _supabase.from('tasks').insert({
      'project_id': projectId,
      'column_id': columnId,
      'user_id': user.id,
      'title': title,
      'description': description,
      'label': label,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Move uma tarefa para outra coluna
  Future<void> moveTask({
    required String taskId,
    required String newColumnId,
  }) async {
    await _supabase
        .from('tasks')
        .update({'column_id': newColumnId})
        .eq('id', taskId);
  }

  // Atualiza os dados de uma tarefa existente
  Future<void> updateTask({
    required String taskId,
    required String title,
    String? description,
    String? label,
    DateTime? dueDate,
    String? assignedTo,
  }) async {
    await _supabase.from('tasks').update({
      'title': title,
      'description': description,
      'label': label,
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
    }).eq('id', taskId);
  }

  // Apaga uma tarefa
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  // Busca todos os perfis para a seleção do responsável
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final response = await _supabase
        .from('profiles')
        .select('id, full_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // --- SUBTAREFAS (CHECKLIST) ---

  Stream<List<SubtaskModel>> getSubtasksStream(String taskId) {
    return _supabase
        .from('subtasks')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => SubtaskModel.fromJson(json)).toList());
  }

  Future<void> addSubtask(String taskId, String title) async {
    await _supabase.from('subtasks').insert({
      'task_id': taskId,
      'title': title,
      'is_completed': false,
    });
  }

  Future<void> toggleSubtask(String subtaskId, bool isCompleted) async {
    await _supabase.from('subtasks').update({
      'is_completed': isCompleted,
    }).eq('id', subtaskId);
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await _supabase.from('subtasks').delete().eq('id', subtaskId);
  }

  // --- COMENTÁRIOS ---

  Stream<List<TaskCommentModel>> getCommentsStream(String taskId) {
    return _supabase
        .from('task_comments')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => TaskCommentModel.fromJson(json)).toList());
  }

  Future<void> addComment({required String taskId, required String content}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('task_comments').insert({
      'task_id': taskId,
      'user_id': user.id,
      'content': content,
    });
  }
}