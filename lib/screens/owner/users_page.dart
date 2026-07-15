import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../data/db_helper.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _loading = true;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await DBHelper.instance.getUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _addUser() async {
    final result = await showDialog<AppUser>(context: context, builder: (_) => const _AddUserDialog());
    if (result == null) return;
    await DBHelper.instance.addUser(result);
    _load();
  }

  Future<void> _resetPassword(AppUser u) async {
    final ctrl = TextEditingController();
    final newPass = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset password for ${u.username}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newPass != null && newPass.isNotEmpty && u.id != null) {
      await DBHelper.instance.updateUserPassword(u.id!, newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
      }
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    if (u.role == 'owner') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('The owner account cannot be removed.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove staff account'),
        content: Text('Remove "${u.fullName}" (${u.username})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: AppColors.accentRed))),
        ],
      ),
    );
    if (confirmed == true && u.id != null) {
      await DBHelper.instance.deleteUser(u.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Users', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Cashier'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Manage staff accounts with access to the POS system.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      final isOwner = u.role == 'owner';
                      return BistroCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  (isOwner ? AppColors.accent2 : AppColors.accentBlue).withValues(alpha: 0.18),
                              child: Icon(isOwner ? Icons.storefront : Icons.badge,
                                  color: isOwner ? AppColors.accent2 : AppColors.accentBlue, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text('@${u.username} · ${u.role}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _resetPassword(u),
                              icon: const Icon(Icons.key, color: AppColors.textSecondary, size: 18),
                              tooltip: 'Reset password',
                            ),
                            if (!isOwner)
                              IconButton(
                                onPressed: () => _deleteUser(u),
                                icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 18),
                                tooltip: 'Remove',
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Cashier Account', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 12),
              TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      text: 'Add',
                      height: 46,
                      onPressed: () {
                        if (_fullName.text.trim().isEmpty ||
                            _username.text.trim().isEmpty ||
                            _password.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
                          return;
                        }
                        Navigator.pop(
                          context,
                          AppUser(
                            username: _username.text.trim(),
                            password: _password.text.trim(),
                            role: 'cashier',
                            fullName: _fullName.text.trim(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
