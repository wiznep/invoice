import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
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
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildSection('Business Information', [
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

              _buildSection('Invoice Settings', [
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

              _buildSection('Data', [
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

              _buildSection('About', [
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
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
