import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trywriting_app/features/tasks/models/task_model.dart';

class ProjectDashboard extends StatelessWidget {
  final List<TaskModel> tasks;

  const ProjectDashboard({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final highPriority = tasks.where((t) => t.priority?.toLowerCase() == 'alta').length;
    final mediumPriority = tasks.where((t) => t.priority?.toLowerCase() == 'média' || t.priority?.toLowerCase() == 'media').length;
    final lowPriority = tasks.where((t) => t.priority?.toLowerCase() == 'baixa').length;

    final total = tasks.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Distribuição por Prioridade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: total == 0
                  ? const Center(child: Text('Nenhuma tarefa para analisar.'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: [
                          PieChartSectionData(
                            value: highPriority.toDouble(),
                            color: Colors.redAccent,
                            title: 'Alta ($highPriority)',
                            radius: 40,
                            titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: mediumPriority.toDouble(),
                            color: Colors.orangeAccent,
                            title: 'Média ($mediumPriority)',
                            radius: 40,
                            titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: lowPriority.toDouble(),
                            color: Colors.grey,
                            title: 'Baixa ($lowPriority)',
                            radius: 40,
                            titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}