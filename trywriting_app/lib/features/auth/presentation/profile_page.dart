import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trywriting_app/config/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = true;
  String? _avatarUrl;
  int _createdTasksCount = 0;
  int _completedTasksCount = 0;
  bool _isPickingImage = false; // Trava para evitar múltiplos cliques

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Carregar Dados do Perfil
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        _nameController.text = profileData['full_name'] ?? '';
        _avatarUrl = profileData['avatar_url'];
      }

      // 2. Carregar Estatísticas do Usuário
      final tasksResponse = await _supabase
          .from('tasks')
          .select('id, column_id');

      setState(() {
        _createdTasksCount = tasksResponse.length;
        // Exemplo: considerar concluídas as tarefas na coluna 'Concluído' ou similar
        _completedTasksCount = tasksResponse.length; 
      });
    } catch (e) {
      // Tratar exceções de carregamento
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _pickAndUploadImage() async {
  // Se já estiver a abrir a galeria ou a fazer upload, ignora novos cliques
  if (_isPickingImage) return;

  final user = _supabase.auth.currentUser;
  if (user == null) return;

  setState(() {
    _isPickingImage = true;
    _isLoading = true;
  });

  try {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (image == null) {
      setState(() {
        _isPickingImage = false;
        _isLoading = false;
      });
      return;
    }

    final imageFile = File(image.path);
    final fileExt = image.path.split('.').last;
    final filePath = '${user.id}/avatar.$fileExt';

    await _supabase.storage.from('avatars').upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'avatar_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() => _avatarUrl = imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar foto: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isPickingImage = false;
        _isLoading = false;
      });
    }
  }
}

  Future<void> _updateProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar dados: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alterar Palavra-passe'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova Palavra-passe',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = _passwordController.text.trim();
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A palavra-passe deve ter pelo menos 6 caracteres.')),
                  );
                  return;
                }

                try {
                  await _supabase.auth.updateUser(
                    UserAttributes(password: newPassword),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Palavra-passe alterada com sucesso!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Atualizar'),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String? email, String? fullName) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName.substring(0, 2).toUpperCase();
    }
    return email?.substring(0, 2).toUpperCase() ?? 'US';
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // AVATAR COM BOTAO DE CAMERA
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? Text(
                                  _getInitials(user?.email, _nameController.text),
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // CARTÕES DE ESTATÍSTICAS
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text('$_createdTasksCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Criadas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text('$_completedTasksCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Concluídas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // FORMULÁRIO DE EDIÇÃO
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Guardar Alterações'),
                    ),
                  ),
                  const Divider(height: 40),

                  // PREFERÊNCIAS E SEGURANÇA
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Alterar Palavra-passe'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Modo Escuro'),
                    value: isDark,
                    onChanged: (_) => AppTheme.toggleTheme(),
                  ),
                  const Divider(height: 40),

                  // BOTÃO DE SAIR DA CONTA
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        await _supabase.auth.signOut();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}