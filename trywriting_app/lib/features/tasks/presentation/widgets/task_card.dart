import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final dynamic task; // Aceita qualquer tipo de modelo de tarefa
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

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
    // Extrai propriedades do modelo de forma segura
    final String title = task.title ?? '';
    final String? description = task.description;
    final String? priority = task.priority;
    final DateTime? dueDate = task.dueDate;

    final priorityColor = _getPriorityColor(priority);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BADGE DE PRIORIDADE COLORIDO
              if (priority != null && priority.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priorityColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // TÍTULO DA TAREFA
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              // DESCRIÇÃO
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // RODAPÉ: DATA DE VENCIMENTO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: dueDate.isBefore(DateTime.now())
                              ? Colors.redAccent
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM').format(dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: dueDate.isBefore(DateTime.now())
                                ? Colors.redAccent
                                : Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),

                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}