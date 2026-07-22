import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../api/api_service.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../ui/animated_gradient_background.dart';
import '../ui/app_chip.dart';
import '../ui/server_wake_banner.dart';
import '../ui/skeletons.dart';
import '../ui/state_views.dart';
import '../widgets/breakdown_list.dart';
import '../widgets/live_badge.dart';
import '../widgets/stat_tile.dart';
import '../widgets/timeseries_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.site});

  final Site site;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Site _site = widget.site;
  StatsRange _range = StatsRange.last7;
  bool _loading = true;
  String? _error;
  StatsSummary _summary = StatsSummary.zero;
  List<StatsPoint> _timeseries = const [];
  Map<BreakdownDimension, List<BreakdownRow>> _breakdowns = const {};
  BreakdownDimension _selectedDimension = BreakdownDimension.page;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final to = DateTime.now();
    final from = to.subtract(Duration(days: _range.days - 1));
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.summary(siteId: _site.id, from: from, to: to),
        api.timeseries(
            siteId: _site.id, from: from, to: to, bucket: _range.bucket),
        for (final dim in BreakdownDimension.values)
          api.breakdown(siteId: _site.id, dim: dim, from: from, to: to),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as StatsSummary;
        _timeseries = results[1] as List<StatsPoint>;
        _breakdowns = {
          for (var i = 0; i < BreakdownDimension.values.length; i++)
            BreakdownDimension.values[i]:
                results[2 + i] as List<BreakdownRow>,
        };
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) {
        await AppStateProvider.of(context).logout();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load stats.';
      });
    }
  }

  void _selectRange(StatsRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _loadData();
  }

  Future<void> _showShareDialog(BuildContext context) async {
    final updated = await showDialog<Site>(
      context: context,
      builder: (_) => _ShareDialog(site: _site),
    );
    if (updated != null && mounted) setState(() => _site = updated);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ServerWakeBanner(),
            Padding(
              padding: EdgeInsets.fromLTRB(t.l, t.l, t.l, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: cs.onSurface),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_site.name,
                            style: AppType.titleL.copyWith(color: cs.onSurface)),
                        Text(_site.domain,
                            style: AppType.caption
                                .copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  LiveBadge(fetchOnline: () => ApiService().live(_site.id)),
                  SizedBox(width: t.s),
                  IconButton(
                    tooltip: 'Share this dashboard',
                    onPressed: () => _showShareDialog(context),
                    icon: Icon(Icons.ios_share, color: cs.onSurfaceVariant),
                  ),
                  for (final r in StatsRange.values) ...[
                    AppChip(
                      label: r.label,
                      selected: r == _range,
                      dense: true,
                      onTap: () => _selectRange(r),
                    ),
                    SizedBox(width: t.xs),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _buildBody(t, cs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppTokens t, ColorScheme cs) {
    if (_loading) {
      return ListView(
        padding: EdgeInsets.all(t.l),
        children: const [ListSkeleton(padding: EdgeInsets.zero)],
      );
    }
    if (_error != null) {
      return ErrorState(title: 'Could not load this dashboard', subtitle: _error, onRetry: _loadData);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(t.l, t.m, t.l, t.xxl),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                  label: 'Pageviews',
                  value: '${_summary.pageviews}',
                  accent: t.chartSeries[0]),
            ),
            SizedBox(width: t.m),
            Expanded(
              child: StatTile(
                  label: 'Visitors',
                  value: '${_summary.visitors}',
                  accent: t.chartSeries[1]),
            ),
          ],
        ),
        SizedBox(height: t.l),
        GlassSurface(
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: t.shadowCard,
          padding: EdgeInsets.all(t.m),
          child: TimeseriesChart(points: _timeseries),
        ),
        SizedBox(height: t.l),
        GlassSurface(
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: t.shadowCard,
          padding: EdgeInsets.all(t.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: t.xs,
                runSpacing: t.xs,
                children: [
                  for (final dim in BreakdownDimension.values)
                    AppChip(
                      label: dim.label,
                      tone: ChipTone.neutral,
                      selected: dim == _selectedDimension,
                      dense: true,
                      onTap: () =>
                          setState(() => _selectedDimension = dim),
                    ),
                ],
              ),
              SizedBox(height: t.m),
              BreakdownList(rows: _breakdowns[_selectedDimension] ?? const []),
            ],
          ),
        ),
      ],
    );
  }
}

/// Create/copy/revoke the site's public share link. Pops with the (possibly
/// updated) [Site] so the dashboard reflects a new or revoked slug without a
/// separate reload.
class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.site});

  final Site site;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  late Site _site = widget.site;
  bool _busy = false;
  String? _error;

  String get _shareUrl => '${Uri.base.origin}/share/${_site.shareSlug}';

  Future<void> _create() => _run(
      () => AppStateProvider.of(context).createShareLink(_site.id),
      'Could not create the share link.');

  Future<void> _revoke() => _run(
      () => AppStateProvider.of(context).revokeShareLink(_site.id),
      'Could not revoke the share link.');

  Future<void> _run(Future<Site> Function() action, String fallbackError) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action();
      if (mounted) setState(() => _site = updated);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = fallbackError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    final hasLink = _site.shareSlug != null;
    return AlertDialog(
      title: const Text('Share this dashboard'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasLink
                  ? 'Anyone with this link sees a read-only view — no login, '
                      'no edit access.'
                  : "This dashboard isn't shared yet. Create a link to give "
                      'anyone read-only access, no login required.',
              style: AppType.body.copyWith(color: cs.onSurfaceVariant),
            ),
            if (hasLink) ...[
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
                  _shareUrl,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: cs.onSurface),
                ),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: t.s),
              Text(_error!,
                  style: AppType.caption.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        if (hasLink)
          TextButton(
            onPressed: _busy ? null : _revoke,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Revoke'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(_site),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _busy ? null : (hasLink ? _copy : _create),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(hasLink ? 'Copy link' : 'Create link'),
        ),
      ],
    );
  }
}
