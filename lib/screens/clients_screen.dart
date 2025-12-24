import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'client_form_screen.dart';

/// Clients list screen
class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          
          appBar: AppBar(
            title: const Text('Clients'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
          ),
          body: appState.clients.isEmpty
              ? EmptyState(
                  icon: Icons.people,
                  title: 'No clients yet',
                  subtitle: 'Add your first client to start creating invoices',
                  buttonLabel: 'Add Client',
                  onButtonPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: appState.clients.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final client = appState.clients[index];
                    return ClientCard(
                      client: client,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientFormScreen(client: client),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'clients_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Client'),
          ),
        );
      },
    );
  }
}
