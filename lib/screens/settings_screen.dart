import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/pdf_service.dart';
import 'items_screen.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final settings = appState.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildSection(context, 'Business Information', [
                _SettingsTile(
                  icon: Icons.business,
                  title: 'Business Name',
                  subtitle: settings.businessName ?? 'Not set',
                  onTap: () => _editSetting(
                    context,
                    'businessName',
                    settings.businessName ?? '',
                  ),
                ),
                _SettingsTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: settings.email ?? 'Not set',
                  onTap: () =>
                      _editSetting(context, 'email', settings.email ?? ''),
                ),
                _SettingsTile(
                  icon: Icons.phone,
                  title: 'Phone',
                  subtitle: settings.phone ?? 'Not set',
                  onTap: () =>
                      _editSetting(context, 'phone', settings.phone ?? ''),
                ),
                _SettingsTile(
                  icon: Icons.location_on,
                  title: 'Address',
                  subtitle: settings.address ?? 'Not set',
                  onTap: () =>
                      _editSetting(context, 'address', settings.address ?? ''),
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              _buildSection(context, 'Invoice Settings', [
                _SettingsTile(
                  icon: Icons.palette,
                  title: 'Invoice Template',
                  subtitle: _getTemplateName(settings.invoiceTemplate),
                  onTap: () => _selectTemplate(context, appState),
                ),
                _SettingsTile(
                  icon: Icons.attach_money,
                  title: 'Currency',
                  subtitle: settings.currency,
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.tag,
                  title: 'Invoice Prefix',
                  subtitle: settings.invoicePrefix,
                  onTap: () => _editSetting(
                    context,
                    'invoicePrefix',
                    settings.invoicePrefix,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.calendar_today,
                  title: 'Default Due Days',
                  subtitle: '${settings.defaultDueDays} days',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              _buildSection(context, 'Data', [
                _SettingsTile(
                  icon: Icons.inventory_2,
                  title: 'Products & Services',
                  subtitle: '${appState.items.length} items',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ItemsScreen()),
                  ),
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              _buildSection(context, 'Appearance', [
                SwitchListTile(
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text('Dark Mode', style: AppTypography.bodyMedium),
                  subtitle: Text(
                    settings.darkMode ? 'On' : 'Off',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: settings.darkMode,
                  onChanged: (value) async {
                    await appState.updateSettings(
                      settings.copyWith(darkMode: value),
                    );
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              _buildSection(context, 'About', [
                const _SettingsTile(
                  icon: Icons.info,
                  title: 'Version',
                  subtitle: '1.0.0',
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  String _getTemplateName(String template) {
    switch (template) {
      case 'classic':
        return 'Classic (Blue)';
      case 'modern':
        return 'Modern (Dark)';
      case 'minimal':
        return 'Minimal (B&W)';
      default:
        return 'Classic (Blue)';
    }
  }

  void _selectTemplate(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Select Invoice Template', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.md),
              _TemplateOption(
                title: 'Classic',
                description: 'Professional blue theme with clean layout',
                icon: Icons.description,
                color: AppColors.primary,
                isSelected: appState.settings.invoiceTemplate == 'classic',
                onTap: () async {
                  await appState.updateSettings(
                    appState.settings.copyWith(invoiceTemplate: 'classic'),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _TemplateOption(
                title: 'Modern',
                description: 'Dark header with teal accents',
                icon: Icons.dark_mode,
                color: const Color(0xFF009688),
                isSelected: appState.settings.invoiceTemplate == 'modern',
                onTap: () async {
                  await appState.updateSettings(
                    appState.settings.copyWith(invoiceTemplate: 'modern'),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _TemplateOption(
                title: 'Minimal',
                description: 'Clean black & white design',
                icon: Icons.notes,
                color: Colors.grey,
                isSelected: appState.settings.invoiceTemplate == 'minimal',
                onTap: () async {
                  await appState.updateSettings(
                    appState.settings.copyWith(invoiceTemplate: 'minimal'),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _editSetting(BuildContext context, String key, String current) {
    final ctrl = TextEditingController(text: current);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit ${key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()}',
        ),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final appState = context.read<AppState>();
              final updated = appState.settings.copyWith(
                businessName: key == 'businessName' ? ctrl.text : null,
                email: key == 'email' ? ctrl.text : null,
                phone: key == 'phone' ? ctrl.text : null,
                address: key == 'address' ? ctrl.text : null,
                invoicePrefix: key == 'invoicePrefix' ? ctrl.text : null,
              );
              await appState.updateSettings(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(title, style: AppTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _TemplateOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
