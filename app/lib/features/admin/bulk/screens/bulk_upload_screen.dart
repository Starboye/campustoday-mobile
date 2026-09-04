import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/bulk_repository.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  String _type = 'students';
  PlatformFile? _file;
  bool _uploading = false;
  BulkImportResult? _result;
  String? _error;

  static const _types = [
    ('students', 'Students'),
    ('marks', 'Marks'),
    ('attendance', 'Attendance'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.bulk)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Bulk Import')),
        body: AdminEmptyView(message: 'You do not have bulk import access.'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Import type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._types.map(
            (entry) => RadioListTile<String>(
              title: Text(entry.$2),
              value: entry.$1,
              groupValue: _type,
              onChanged: _uploading
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(_file?.name ?? 'Choose CSV file'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _uploading || _file == null ? null : _upload,
            child: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Upload'),
          ),
          if (_uploading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Uploading and processing…'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_result!.message, style: Theme.of(context).textTheme.titleMedium),
                    if (_result!.imported != null) Text('Imported: ${_result!.imported}'),
                    if (_result!.failed != null) Text('Failed: ${_result!.failed}'),
                    if (_result!.errors != null && _result!.errors!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Errors:'),
                      ..._result!.errors!.take(5).map((e) => Text('• $e')),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.first;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _upload() async {
    final path = _file?.path;
    if (path == null) return;

    setState(() {
      _uploading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await ref.read(bulkRepositoryProvider).upload(
            type: _type,
            filePath: path,
            fileName: _file!.name,
          );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _uploading = false);
    }
  }
}
