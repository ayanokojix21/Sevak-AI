import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/auth_providers.dart';
import '../../../dashboard/domain/entities/ngo_entity.dart';
import '../../domain/entities/join_request_entity.dart';
import '../../data/datasources/join_request_datasource.dart';
import '../../../../providers/ngo_providers.dart';

/// Browse NGOs page — Clash of Clans clan discovery style.
/// Users can search, view details, and request to join.
class NgoDiscoveryPage extends ConsumerStatefulWidget {
  const NgoDiscoveryPage({super.key});

  @override
  ConsumerState<NgoDiscoveryPage> createState() => _NgoDiscoveryPageState();
}

class _NgoDiscoveryPageState extends ConsumerState<NgoDiscoveryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ngosAsync = ref.watch(activeNgosProvider);
    final profileAsync = ref.watch(volunteerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover NGOs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search NGOs by name or city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Register CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/register-ngo'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_business, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Register Your Own NGO',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              'Create and manage your organization',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // NGO list
          Expanded(
            child: ngosAsync.when(
              data: (ngos) {
                final filtered = ngos.where((ngo) {
                  if (_searchQuery.isEmpty) return true;
                  return ngo.name.toLowerCase().contains(_searchQuery) ||
                      ngo.city.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No NGOs match "$_searchQuery"'
                              : 'No NGOs available yet',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _NgoCard(
                    ngo: filtered[i],
                    userId: profileAsync.value?.uid ?? '',
                    userName: profileAsync.value?.name ?? '',
                    userEmail: profileAsync.value?.email ?? '',
                    isMember: profileAsync.value?.isMemberOf(filtered[i].id) ?? false,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NgoCard extends ConsumerStatefulWidget {
  final NgoEntity ngo;
  final String userId;
  final String userName;
  final String userEmail;
  final bool isMember;

  const _NgoCard({
    required this.ngo,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.isMember,
  });

  @override
  ConsumerState<_NgoCard> createState() => _NgoCardState();
}

class _NgoCardState extends ConsumerState<_NgoCard> {
  bool _expanded = false;

  void _showJoinDialog() {
    // Check if profile has skills — CU users need to fill details before joining
    final profile = ref.read(volunteerProfileProvider).value;
    if (profile != null && profile.skills.isEmpty) {
      SnackbarUtils.showError(
        context,
        'Please complete your profile first to join an NGO',
      );
      context.push('/profile-setup');
      return;
    }

    final msgController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Join ${widget.ngo.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Write a short message to the NGO admin:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Why do you want to join? (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final request = JoinRequest(
                  id: '',
                  userId: widget.userId,
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                  ngoId: widget.ngo.id,
                  ngoName: widget.ngo.name,
                  status: 'pending',
                  message: msgController.text.trim(),
                  createdAt: DateTime.now(),
                );
                await ref.read(joinRequestDatasourceProvider).sendJoinRequest(request);
                if (mounted) {
                  SnackbarUtils.showSuccess(context, 'Join request sent! Awaiting approval.');
                }
              } catch (e) {
                if (mounted) {
                  SnackbarUtils.showError(context, e.toString());
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiary),
            child: Text('Send Request', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // NGO icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ngo.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              SizedBox(width: 3),
                              Text(
                                widget.ngo.city.isNotEmpty ? widget.ngo.city : 'Location TBD',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.people_outline, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              SizedBox(width: 3),
                              Text(
                                '${widget.ngo.volunteerCount} members',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status / action
                    if (widget.isMember)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Joined',
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),

                // Expanded details
                if (_expanded) ...[
                  SizedBox(height: 16),
                  Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                  SizedBox(height: 16),
                  if (widget.ngo.operatingAreas.isNotEmpty) ...[
                    Text(
                      'OPERATING AREAS',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.ngo.operatingAreas.map((area) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(area, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!widget.isMember)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _showJoinDialog,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Request to Join'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}