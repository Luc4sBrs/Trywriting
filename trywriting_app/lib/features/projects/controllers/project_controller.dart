import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

class ProjectController {
  final _supabase = Supabase.instance.client;

  // Busca todos os projetos em que o utilizador é o criador
  Future<List<ProjectModel>> fetchUserProjects() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilizador não autenticado.');

    final response = await _supabase
        .from('projects')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ProjectModel.fromJson(json))
        .toList();
  }

  // Cria um novo projeto e associa ao utilizador atual
  Future<ProjectModel> createProject({
    required String title,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilizador não autenticado.');

    final response = await _supabase
        .from('projects')
        .insert({
          'title': title,
          'description': description,
          'owner_id': userId,
        })
        .select()
        .single();

    return ProjectModel.fromJson(response);
  }
}