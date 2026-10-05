import 'package:flutter/material.dart';
import 'package:trywriting_app/features/tasks/models/subtask_model.dart';
import '../controllers/task_controller.dart';
import '../models/task_comment_model.dart';
import '../models/task_model.dart';

class EditTaskDialog extends StatefulWidget {
  final TaskModel task;

  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _commentController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _taskController = TaskController();

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    await _taskController.addComment(
      taskId: widget.task.id,
      content: text,
    );
  }

  Future<void> _addSubtask() async {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    _subtaskController.clear();
    await _taskController.addSubtask(widget.task.id, text);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.task.description != null &&
                  widget.task.description!.isNotEmpty) ...[
                Text(
                  widget.task.description!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Divider(height: 24),
              ],

              // --- SECÇÃO DE SUBTAREFAS / CHECKLIST ---
              const Text(
                'Checklist / Subtarefas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<SubtaskModel>>(
                stream: _taskController.getSubtasksStream(widget.task.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final subtasks = snapshot.data!;

                  return Column(
                    children: [
                      if (subtasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Nenhuma subtarefa adicionada.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ...subtasks.map((subtask) => CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              subtask.title,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: subtask.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            value: subtask.isCompleted,
                            onChanged: (val) {
                              if (val != null) {
                                _taskController.toggleSubtask(
                                    subtask.id, val);
                              }
                            },
                            secondary: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 16, color: Colors.redAccent),
                              onPressed: () =>
                                  _taskController.deleteSubtask(subtask.id),
                            ),
                          )),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              decoration: const InputDecoration(
                                hintText: 'Adicionar sub-item...',
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addSubtask,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const Divider(height: 24),

              // --- SECÇÃO DE COMENTÁRIOS ---
              const Text(
                'Comentários',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 160,
                child: StreamBuilder<List<TaskCommentModel>>(
                  stream: _taskController.getCommentsStream(widget.task.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum comentário ainda.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.white10
                                : Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            comment.content,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // CAMPO PARA NOVO COMENTÁRIO
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendComment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}