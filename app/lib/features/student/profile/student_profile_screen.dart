import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../data/student_repository.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPass.text != _confirm.text) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref.read(studentRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _newPass.text,
          );
      setState(() => _message = 'Password updated. Please sign in again.');
      await Future<void>.delayed(const Duration(seconds: 1));
      await ref.read(authControllerProvider.notifier).logout();
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text(user?.name ?? ''),
          subtitle: Text('ID: ${user?.id ?? ''}'),
        ),
        const Divider(),
        Text('Change password', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _current,
          decoration: const InputDecoration(labelText: 'Current password'),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPass,
          decoration: const InputDecoration(labelText: 'New password'),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          decoration: const InputDecoration(labelText: 'Confirm new password'),
          obscureText: true,
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _changePassword,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Update password'),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
    );
  }
}
