import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/api_service.dart';
import '../models/models.dart';
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

/// PS-032 — the public, read-only mirror of [DashboardScreen] a share link
/// opens straight into (no login). Same layout, no delete/logout controls,
/// data comes from the no-auth `ApiService().public*` calls keyed by [slug]
/// instead of a site id + bearer token.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.slug});

  final String slug;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  StatsRange _range = StatsRange.last7;
  bool _loading = true;
  bool _revoked = false;
  String? _error;
  PublicSite? _site;
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
      _revoked = false;
      _error = null;
    });
    final to = DateTime.now();
    final from = to.subtract(Duration(days: _range.days - 1));
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.publicSite(widget.slug),
        api.publicSummary(slug: widget.slug, from: from, to: to),
        api.publicTimeseries(
            slug: widget.slug, from: from, to: to, bucket: _range.bucket),
        for (final dim in BreakdownDimension.values)
          api.publicBreakdown(slug: widget.slug, dim: dim, from: from, to: to),
      ]);
      if (!mounted) return;
      setState(() {
        _site = results[0] as PublicSite;
        _summary = results[1] as StatsSummary;
        _timeseries = results[2] as List<StatsPoint>;
        _breakdowns = {
          for (var i = 0; i < BreakdownDimension.values.length; i++)
            BreakdownDimension.values[i]: results[3 + i] as List<BreakdownRow>,
        };
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _revoked = e.kind == ApiErrorKind.notFound;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this dashboard.';
      });
    }
  }

  void _selectRange(StatsRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _loadData();
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_site?.name ?? 'Shared dashboard',
                            style: AppType.titleL.copyWith(color: cs.onSurface)),
                        if (_site != null)
                          Text(_site!.domain,
                              style: AppType.caption
                                  .copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (_site != null) ...[
                    LiveBadge(
                        fetchOnline: () => ApiService().publicLive(widget.slug)),
                    SizedBox(width: t.m),
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
    if (_revoked) {
      return const EmptyState(
        icon: Icons.link_off,
        title: 'This link is no longer active',
        subtitle: 'The owner may have revoked it, or it never existed.',
      );
    }
    if (_error != null) {
      return ErrorState(
          title: 'Could not load this dashboard',
          subtitle: _error,
          onRetry: _loadData);
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
              BreakdownList(
                rows: _breakdowns[_selectedDimension] ?? const [],
                dimension: _selectedDimension,
              ),
            ],
          ),
        ),
        SizedBox(height: t.l),
        Center(
          child: Text(
            'Privacy-first analytics by Plainsight — no cookies, no IP storage.',
            style: AppType.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
