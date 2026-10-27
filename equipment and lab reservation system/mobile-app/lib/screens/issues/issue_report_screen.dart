import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/equipment_model.dart';
import '../../models/laboratory_model.dart';
import '../../services/equipment_service.dart';
import '../../services/issue_service.dart';
import '../../services/laboratory_service.dart';
import '../../widgets/loading_widget.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({super.key});

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final _description = TextEditingController();
  final _picker = ImagePicker();
  final _issues = IssueService();
  List<EquipmentModel> _equipment = [];
  List<LaboratoryModel> _laboratories = [];
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  bool _saving = false;
  String _resourceType = 'equipment';
  int? _resourceId;
  String? _photoPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait([
        EquipmentService().list(),
        LaboratoryService().list(),
        _issues.list(),
      ]);
      if (!mounted) return;
      setState(() {
        _equipment = result[0] as List<EquipmentModel>;
        _laboratories = result[1] as List<LaboratoryModel>;
        _reports = result[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the report form: $error';
        });
      }
    }
  }

  Future<void> _choosePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file != null && mounted) setState(() => _photoPath = file.path);
  }

  Future<void> _submit() async {
    if (_resourceId == null || _description.text.trim().isEmpty) {
      setState(() => _error = 'Choose a resource and describe the problem.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _issues.create(
        description: _description.text.trim(),
        equipmentId: _resourceType == 'equipment' ? _resourceId : null,
        laboratoryId: _resourceType == 'laboratory' ? _resourceId : null,
        photoPath: _photoPath,
      );
      _description.clear();
      setState(() {
        _photoPath = null;
        _resourceId = null;
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problem reported. Staff have been notified.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Report could not be submitted: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: _loading
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'Report damaged equipment, missing accessories, or a laboratory issue. Staff will receive an in-app notification.',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _resourceType,
                  decoration: const InputDecoration(labelText: 'Resource type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'equipment',
                      child: Text('Equipment'),
                    ),
                    DropdownMenuItem(
                      value: 'laboratory',
                      child: Text('Laboratory'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _resourceType = value ?? 'equipment';
                          _resourceId = null;
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('$_resourceType-$_resourceId'),
                  initialValue: _resourceId,
                  decoration: InputDecoration(
                    labelText: _resourceType == 'equipment'
                        ? 'Equipment'
                        : 'Laboratory',
                  ),
                  items: _resourceType == 'equipment'
                      ? _equipment
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList()
                      : _laboratories
                            .map(
                              (room) => DropdownMenuItem(
                                value: room.id,
                                child: Text(
                                  room.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                  onChanged: (value) => setState(() => _resourceId = value),
                  validator: (value) =>
                      value == null ? 'Select a resource' : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Describe the damage or problem',
                    alignLabelWithHint: true,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _choosePhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _photoPath == null
                        ? 'Attach a photo (optional)'
                        : 'Choose a different photo',
                  ),
                ),
                if (_photoPath != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Photo selected: ${_photoPath!.split(RegExp(r'[/\\]')).last}',
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Submitting...' : 'Submit report'),
                ),
                const Divider(height: 36),
                Text(
                  'My reports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No reports submitted yet.'),
                  ),
                for (final report in _reports)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.report_problem_outlined),
                    title: Text(
                      report['equipment_name'] as String? ??
                          report['laboratory_name'] as String? ??
                          'Resource issue',
                    ),
                    subtitle: Text(
                      '${report['description']}\nStatus: ${report['status']}',
                    ),
                    isThreeLine: true,
                    trailing: report['photo'] == null
                        ? null
                        : const Icon(Icons.image_outlined),
                  ),
              ],
            ),
    );
  }
}
