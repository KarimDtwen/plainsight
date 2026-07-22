import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/transitions.dart';
import '../ui/animated_gradient_background.dart';
import '../ui/app_button.dart';
import '../ui/app_input.dart';
import '../ui/section_header.dart';
import '../ui/server_wake_banner.dart';
import '../ui/skeletons.dart';
import '../ui/state_views.dart';
import 'dashboard_screen.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    final app = AppStateProvider.of(context);

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ServerWakeBanner(),
            Padding(
              padding: EdgeInsets.fromLTRB(t.l, t.l, t.l, t.s),
              child: SectionHeader(
                title: 'Your sites',
                subtitle: 'Pick a site to see its dashboard',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Add site',
                      onPressed: () => _showAddSiteDialog(context),
                      icon: Icon(Icons.add_circle,
                          color: AppColors.electric, size: 28),
                    ),
                    IconButton(
                      tooltip: 'Log out',
                      onPressed: app.logout,
                      icon: Icon(Icons.logout, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody(context, app)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppState app) {
    if (app.sitesLoading && app.sites.isEmpty) {
      return const ListSkeleton();
    }
    if (app.sitesError != null && app.sites.isEmpty) {
      return ErrorState(
        title: 'Could not load your sites',
        subtitle: app.sitesError,
        onRetry: app.loadSites,
      );
    }
    if (app.sites.isEmpty) {
      return EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'No sites yet',
        subtitle: 'Add a site to get its tracking snippet.',
        action: AppSecondaryButton(
          label: 'Add your first site',
          icon: Icons.add,
          expand: false,
          onPressed: () => _showAddSiteDialog(context),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: app.loadSites,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: app.sites.length,
        itemBuilder: (context, i) => _SiteCard(site: app.sites[i]),
      ),
    );
  }

  Future<void> _showAddSiteDialog(BuildContext context) async {
    final site = await showDialog<Site>(
      context: context,
      builder: (_) => const _AddSiteDialog(),
    );
    if (site != null && context.mounted) {
      await _showSnippetDialog(context, site);
    }
  }

  Future<void> _showSnippetDialog(BuildContext context, Site site) {
    final snippet = site.installSnippet ??
        '<script defer src="${Uri.parse(_baseUrlPlaceholder)}/js/script.js" '
            'data-site="${site.siteKey}"></script>';
    return showDialog(
      context: context,
      builder: (dialogContext) {
        final t = dialogContext.tokens;
        final cs = dialogContext.scheme;
        return AlertDialog(
          title: Text('${site.name} is ready'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste this one line before </body> on every page you want '
                  'to track:',
                  style: AppType.body.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: t.s),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(t.s),
                  decoration: BoxDecoration(
                    color: cs.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(t.radiusMd),
                  ),
                  child: SelectableText(
                    snippet,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: snippet));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

// Only used as a fallback if a site somehow lacks install_snippet (should not
// happen — POST /sites always returns it) so the dialog never renders blank.
const _baseUrlPlaceholder = 'https://your-backend';

/// A real StatefulWidget (not a manually-managed showDialog + StatefulBuilder)
/// so its TextEditingControllers are disposed by the framework exactly when
/// this dialog's route is actually unmounted — after its exit transition
/// finishes, not the instant `showDialog`'s Future resolves. Disposing them
/// manually right after the Future completed caused "TextEditingController
/// used after being disposed" on a live run: the AlertDialog's fade-out was
/// still animating (and its TextFields still mounted) at that point.
class _AddSiteDialog extends StatefulWidget {
  const _AddSiteDialog();

  @override
  State<_AddSiteDialog> createState() => _AddSiteDialogState();
}

class _AddSiteDialogState extends State<_AddSiteDialog> {
  final _nameController = TextEditingController();
  final _domainController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _domainController.text.isEmpty) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final site = await AppStateProvider.of(context).createSite(
        name: _nameController.text,
        domain: _domainController.text,
      );
      if (mounted) Navigator.of(context).pop(site);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not add the site.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AlertDialog(
      title: const Text('Add a site'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchField(
            controller: _nameController,
            hintText: 'Site name (e.g. My Blog)',
            prefixIcon: Icons.label_outline,
          ),
          SizedBox(height: t.s),
          AppSearchField(
            controller: _domainController,
            hintText: 'Domain (e.g. example.com)',
            prefixIcon: Icons.public,
          ),
          if (_error != null) ...[
            SizedBox(height: t.s),
            Text(_error!,
                style: AppType.caption.copyWith(color: AppColors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site});
  final Site site;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    return Padding(
      padding: EdgeInsets.only(bottom: t.m),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(t.radiusLg),
          onTap: () => Navigator.of(context)
              .push(slideRightRoute(DashboardScreen(site: site))),
          child: GlassSurface(
            borderRadius: BorderRadius.circular(t.radiusLg),
            boxShadow: t.shadowCard,
            padding: EdgeInsets.all(t.m + 2),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.electric.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(t.radiusMd),
                  ),
                  child: const Icon(Icons.language, color: AppColors.electric),
                ),
                SizedBox(width: t.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(site.name,
                          style:
                              AppType.titleS.copyWith(color: cs.onSurface)),
                      Text(site.domain,
                          style: AppType.caption
                              .copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete site',
                  onPressed: () => _confirmDelete(context, site),
                  icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Site site) async {
    final app = AppStateProvider.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this site?'),
        content: Text(
            '"${site.name}" and all of its collected data will be removed. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await app.deleteSite(site.id);
    }
  }
}
