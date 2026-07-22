/// A registered site: one row from `GET/POST /sites`.
class Site {
  const Site({
    required this.id,
    required this.siteKey,
    required this.domain,
    required this.name,
    this.shareSlug,
    required this.createdAt,
    this.installSnippet,
  });

  final String id;
  final String siteKey;
  final String domain;
  final String name;
  final String? shareSlug;
  final DateTime createdAt;
  // Only present on the POST /sites response — the ready-to-paste <script> tag.
  final String? installSnippet;

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        id: json['id'] as String,
        siteKey: json['site_key'] as String,
        domain: json['domain'] as String,
        name: json['name'] as String,
        shareSlug: json['share_slug'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        installSnippet: json['install_snippet'] as String?,
      );
}

/// One bucket of `GET /stats/timeseries`.
class StatsPoint {
  const StatsPoint({
    required this.bucket,
    required this.pageviews,
    required this.visitors,
  });

  final DateTime bucket;
  final int pageviews;
  final int visitors;

  factory StatsPoint.fromJson(Map<String, dynamic> json) => StatsPoint(
        bucket: DateTime.parse(json['bucket'] as String),
        pageviews: (json['pageviews'] as num).toInt(),
        visitors: (json['visitors'] as num).toInt(),
      );
}

/// One row of `GET /stats/breakdown` (a page path, referrer host, country, …).
class BreakdownRow {
  const BreakdownRow({
    required this.value,
    required this.pageviews,
    required this.visitors,
  });

  final String value;
  final int pageviews;
  final int visitors;

  factory BreakdownRow.fromJson(Map<String, dynamic> json) => BreakdownRow(
        value: json['value'] as String,
        pageviews: (json['pageviews'] as num).toInt(),
        visitors: (json['visitors'] as num).toInt(),
      );
}

/// `GET /stats/summary`.
class StatsSummary {
  const StatsSummary({required this.pageviews, required this.visitors});

  final int pageviews;
  final int visitors;

  static const zero = StatsSummary(pageviews: 0, visitors: 0);

  factory StatsSummary.fromJson(Map<String, dynamic> json) => StatsSummary(
        pageviews: (json['pageviews'] as num?)?.toInt() ?? 0,
        visitors: (json['visitors'] as num?)?.toInt() ?? 0,
      );
}

/// The breakdown dimensions the backend understands (`/stats/breakdown?dim=`).
enum BreakdownDimension { page, referrer, country, device, browser }

extension BreakdownDimensionName on BreakdownDimension {
  String get apiValue => name;

  String get label => switch (this) {
        BreakdownDimension.page => 'Top pages',
        BreakdownDimension.referrer => 'Top referrers',
        BreakdownDimension.country => 'Countries',
        BreakdownDimension.device => 'Devices',
        BreakdownDimension.browser => 'Browsers',
      };
}

/// A date range for stats queries — the range-picker's quick-select options.
enum StatsRange { last7, last30, last90 }

extension StatsRangeSpan on StatsRange {
  String get label => switch (this) {
        StatsRange.last7 => '7 days',
        StatsRange.last30 => '30 days',
        StatsRange.last90 => '90 days',
      };

  int get days => switch (this) {
        StatsRange.last7 => 7,
        StatsRange.last30 => 30,
        StatsRange.last90 => 90,
      };

  String get bucket => this == StatsRange.last90 ? 'week' : 'day';
}
