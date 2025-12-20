import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/settings/settings_service.dart';
import '../../core/theme/app_theme.dart';

/// First-run setup screen for selecting database location
class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _useDefaultLocation = true;
  String? _customPath;
  String _defaultPath = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    final defaultPath = await SettingsService.instance.getDefaultDbPath();
    setState(() {
      _defaultPath = defaultPath;
    });
  }

  Future<void> _selectCustomPath() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Database Location',
    );

    if (result != null) {
      setState(() {
        _customPath = result;
        _useDefaultLocation = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectedPath = _useDefaultLocation ? _defaultPath : _customPath;

      if (selectedPath == null || selectedPath.isEmpty) {
        setState(() {
          _errorMessage = 'Please select a valid location';
          _isLoading = false;
        });
        return;
      }

      // Save the selected path
      await SettingsService.instance.setDbPath(selectedPath);
      await SettingsService.instance.completeFirstRun();

      // Notify parent that setup is complete
      widget.onSetupComplete();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save settings: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.storage_rounded,
                        size: 80,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to BARCF Reports',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose where to store your database',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Location Options Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Default Location Option
                        _buildLocationOption(
                          title: 'Default Location',
                          subtitle: _defaultPath.isNotEmpty
                              ? _defaultPath
                              : 'Loading...',
                          icon: Icons.folder_outlined,
                          isSelected: _useDefaultLocation,
                          onTap: () {
                            setState(() {
                              _useDefaultLocation = true;
                              _errorMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),

                        // Custom Location Option
                        _buildLocationOption(
                          title: 'Custom Location',
                          subtitle: _customPath ?? 'Click to select folder...',
                          icon: Icons.folder_special_outlined,
                          isSelected: !_useDefaultLocation,
                          onTap: _selectCustomPath,
                          showBrowseButton: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Path Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Database will be stored at:\n${_useDefaultLocation ? _defaultPath : (_customPath ?? 'Select a location')}',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continue,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool showBrowseButton = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAccent
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? AppTheme.primaryAccent : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showBrowseButton)
              TextButton(
                onPressed: onTap,
                child: const Text('Browse'),
              ),
            Radio<bool>(
              value: !showBrowseButton ? true : false,
              groupValue: _useDefaultLocation,
              onChanged: (value) => onTap(),
              activeColor: AppTheme.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }
}
