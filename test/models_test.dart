import 'package:flutter_test/flutter_test.dart';

import 'package:plainsight/models/models.dart';

void main() {
  test('Site.fromJson parses the /sites response shape', () {
    final site = Site.fromJson({
      'id': 'abc-123',
      'site_key': 'deadbeef',
      'domain': 'example.com',
      'name': 'My Blog',
      'share_slug': null,
      'created_at': '2026-07-22T09:25:24.258362+00:00',
      'install_snippet': '<script defer src="..."></script>',
    });
    expect(site.id, 'abc-123');
    expect(site.siteKey, 'deadbeef');
    expect(site.shareSlug, isNull);
    expect(site.installSnippet, contains('<script'));
  });

  test('StatsSummary.fromJson defaults missing fields to zero', () {
    final summary = StatsSummary.fromJson(const {});
    expect(summary.pageviews, 0);
    expect(summary.visitors, 0);
  });

  test('BreakdownDimension.apiValue matches the backend query param', () {
    expect(BreakdownDimension.page.apiValue, 'page');
    expect(BreakdownDimension.referrer.apiValue, 'referrer');
  });

  test('StatsRange picks day buckets except for the 90-day range', () {
    expect(StatsRange.last7.bucket, 'day');
    expect(StatsRange.last30.bucket, 'day');
    expect(StatsRange.last90.bucket, 'week');
  });
}
