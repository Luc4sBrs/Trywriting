import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String? _selectedPriorityFilter;

  @override
  void initState() {
    super.initState();
    _taskController = TaskController();
    _initBoard();
  }

  Future<void> _initBoard() async {
    try {
      await _taskController.createDefaultColumns(widget.projectId);
      await _reloadColumns();
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

  Future<void> _reloadColumns() async {
    final columns = await _taskController.fetchColumns(widget.projectId);
    if (mounted) {
      setState(() {
        _columns = columns;
        _isLoadingColumns = false;
      });
    }
  }

  // DIÁLOGO PARA CRIAR NOVA COLUNA
  void _showAddColumnDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Coluna'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da Coluna',
            hintText: 'Ex: Em Revisão, QA, Aprovado',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                await _taskController.createColumn(widget.projectId, title);
                await _reloadColumns();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  // DIÁLOGO PARA EDITAR NOME DA COLUNA
  void _showEditColumnDialog(ColumnModel column) {
    final controller = TextEditingController(text: column.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Coluna'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da Coluna'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != column.title) {
                await _taskController.updateColumnTitle(column.id, newTitle);
                await _reloadColumns();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ELIMINAR COLUNA
  Future<void> _deleteColumn(ColumnModel column, int taskCount) async {
    if (taskCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível eliminar colunas com tarefas. Move ou apaga as tarefas primeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Coluna'),
        content: Text('Tem a certeza que deseja eliminar a coluna "${column.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _taskController.deleteColumn(column.id);
      await _reloadColumns();
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

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'média':
      case 'media':
        return Colors.orangeAccent;
      case 'baixa':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
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
                        itemCount: _columns.length + 1, // +1 para o botão de Adicionar Coluna
                        itemBuilder: (context, index) {
                          // CARD DE ADICIONAR NOVA COLUNA NO FINAL
                          if (index == _columns.length) {
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 16),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.view_column_outlined),
                                label: const Text('Nova Coluna'),
                                onPressed: _showAddColumnDialog,
                              ),
                            );
                          }

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
                                    content: Text('Movido "${details.data.title}" para ${column.title}'),
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
                                    // CABEÇALHO DA COLUNA COM MENU
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${column.title} (${columnTasks.length})',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 20),
                                            onPressed: () => _showAddTaskDialog(column.id, column.title),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                            onSelected: (val) {
                                              if (val == 'edit') {
                                                _showEditColumnDialog(column);
                                              } else if (val == 'delete') {
                                                _deleteColumn(column, columnTasks.length);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 16),
                                                    SizedBox(width: 8),
                                                    Text('Editar nome'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                                    SizedBox(width: 8),
                                                    Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                                              elevation: 8,
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.transparent,
                                              child: Transform.rotate(
                                                angle: 0.05,
                                                child: SizedBox(
                                                  width: 270,
                                                  child: _buildTaskCardContent(task, isDark),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.2,
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
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Tarefa'),
            content: Text('Tem a certeza que deseja eliminar "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _taskController.deleteTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tarefa "${task.title}" eliminada')),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: _buildTaskCardContent(task, isDark),
    );
  }

  Widget _buildTaskCardContent(TaskModel task, bool isDark) {
    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditTaskDialog(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.priority != null && task.priority!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: priorityColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        task.priority!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  SizedBox(
                    height: 24,
                    width: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showEditTaskDialog(task);
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar Tarefa'),
                              content: Text('Tem a certeza que deseja eliminar "${task.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _taskController.deleteTask(task.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Editar', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],

              if (task.dueDate != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: task.dueDate!.isBefore(DateTime.now())
                          ? Colors.redAccent
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM').format(task.dueDate!),
                      style: TextStyle(
                        fontSize: 11,
                        color: task.dueDate!.isBefore(DateTime.now())
                            ? Colors.redAccent
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}