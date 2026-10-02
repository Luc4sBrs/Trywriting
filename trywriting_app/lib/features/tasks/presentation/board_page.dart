import 'package:flutter/material.dart';
import 'package:trywriting_app/config/app_theme.dart';
import 'package:trywriting_app/core/services/notification_service.dart';
import 'package:trywriting_app/shared/widgets/shimmer_loading.dart';
import '../controllers/task_controller.dart';
import '../models/column_model.dart';
import '../models/task_model.dart';
import 'edit_task_dialog.dart';

class BoardPage extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const BoardPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late final TaskController _taskController;
  List<ColumnModel> _columns = [];
  bool _isLoadingColumns = true;

  // Estados de Pesquisa e Filtros
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedPriorityFilter; // 'Baixa', 'Média', 'Alta' ou null (todas)

  @override
  void initState() {
    super.initState();
    _taskController = TaskController();
    _initBoard();
  }

  Future<void> _initBoard() async {
    try {
      await _taskController.createDefaultColumns(widget.projectId);
      final columns = await _taskController.fetchColumns(widget.projectId);
      if (mounted) {
        setState(() {
          _columns = columns;
          _isLoadingColumns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar colunas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditTaskDialog(TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  void _showAddTaskDialog(String columnId, String columnTitle) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'Média';
    DateTime? selectedDueDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nova Tarefa em "$columnTitle"'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Título da Tarefa'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Informe o título' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: const InputDecoration(labelText: 'Prioridade'),
                        items: ['Baixa', 'Média', 'Alta'].map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedPriority = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, size: 20),
                        title: Text(
                          selectedDueDate == null
                              ? 'Definir Data Limite'
                              : 'Prazo: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final taskTitle = titleController.text.trim();

                    await _taskController.createTask(
                      projectId: widget.projectId,
                      columnId: columnId,
                      title: taskTitle,
                      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    );

                    if (selectedDueDate != null) {
                      await NotificationService().scheduleTaskNotification(
                        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                        title: 'Lembrete de Tarefa',
                        body: 'A tarefa "$taskTitle" vence hoje!',
                        scheduledDate: selectedDueDate!,
                      );
                    }

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar tarefa...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase().trim();
                  });
                },
              )
            : Text(widget.projectTitle),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            tooltip: 'Alternar Tema',
            onPressed: () => AppTheme.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE FILTROS POR PRIORIDADE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _selectedPriorityFilter == null,
                    onSelected: (_) => setState(() => _selectedPriorityFilter = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Alta'),
                    selected: _selectedPriorityFilter == 'Alta',
                    onSelected: (_) => setState(() {
                      _selectedPriorityFilter = _selectedPriorityFilter == 'Alta' ? null : 'Alta';
                    }),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Média'),
                    selected: _selectedPriorityFilter == 'Média',
                    onSelected: (_) => setState(() {
                      _selectedPriorityFilter = _selectedPriorityFilter == 'Média' ? null : 'Média';
                    }),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Baixa'),
                    selected: _selectedPriorityFilter == 'Baixa',
                    onSelected: (_) => setState(() {
                      _selectedPriorityFilter = _selectedPriorityFilter == 'Baixa' ? null : 'Baixa';
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoadingColumns
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => const ColumnSkeleton(),
                  )
                : StreamBuilder<List<TaskModel>>(
                    stream: _taskController.getTasksStream(widget.projectId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));

                      if (!snapshot.hasData) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(16),
                          itemCount: _columns.length,
                          itemBuilder: (context, index) => const ColumnSkeleton(),
                        );
                      }

                      var allTasks = snapshot.data!;

                      // FILTRAGEM POR BUSCA E PRIORIDADE
                      if (_searchQuery.isNotEmpty) {
                        allTasks = allTasks.where((t) {
                          final titleMatch = t.title.toLowerCase().contains(_searchQuery);
                          final descMatch = t.description?.toLowerCase().contains(_searchQuery) ?? false;
                          return titleMatch || descMatch;
                        }).toList();
                      }

                      if (_selectedPriorityFilter != null) {
                        allTasks = allTasks
                            .where((t) => t.priority?.toLowerCase() == _selectedPriorityFilter!.toLowerCase())
                            .toList();
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(16),
                        itemCount: _columns.length,
                        itemBuilder: (context, index) {
                          final column = _columns[index];
                          final columnTasks = allTasks.where((t) => t.columnId == column.id).toList();

                          return DragTarget<TaskModel>(
                            onWillAcceptWithDetails: (details) => details.data.columnId != column.id,
                            onAcceptWithDetails: (details) async {
                              await _taskController.moveTask(
                                taskId: details.data.id,
                                newColumnId: column.id,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Movidi "${details.data.title}" para ${column.title}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                width: 290,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: candidateData.isNotEmpty
                                      ? (isDark ? Colors.white10 : Colors.black12)
                                      : (isDark ? const Color(0xFF181818) : const Color(0xFFEFEFEF)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${column.title} (${columnTasks.length})',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 20),
                                            onPressed: () => _showAddTaskDialog(column.id, column.title),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(10),
                                        itemCount: columnTasks.length,
                                        itemBuilder: (context, taskIndex) {
                                          final task = columnTasks[taskIndex];

                                          return LongPressDraggable<TaskModel>(
                                            data: task,
                                            feedback: Material(
                                              elevation: 6,
                                              borderRadius: BorderRadius.circular(12),
                                              child: SizedBox(
                                                width: 270,
                                                child: Card(
                                                  child: ListTile(
                                                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.3,
                                              child: _buildTaskCard(task, isDark, column),
                                            ),
                                            child: _buildTaskCard(task, isDark, column),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool isDark, ColumnModel currentColumn) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _showEditTaskDialog(task),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white54 : Colors.black54),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priority?.toUpperCase() ?? 'MÉDIA',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                  const SizedBox(width: 2),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}',
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}