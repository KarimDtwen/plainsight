from services import hashing, salt_cache
from services import ip as ip_service
from services import ua as ua_service


# ── hashing ────────────────────────────────────────────────────────────────


def test_visitor_hash_deterministic():
    a = hashing.visitor_hash("salt", "site", "1.2.3.4", "UA")
    b = hashing.visitor_hash("salt", "site", "1.2.3.4", "UA")
    assert a == b
    assert len(a) == 32
    assert all(c in "0123456789abcdef" for c in a)


def test_visitor_hash_varies_by_every_input():
    base = hashing.visitor_hash("salt", "site", "1.2.3.4", "UA")
    assert hashing.visitor_hash("SALT2", "site", "1.2.3.4", "UA") != base
    assert hashing.visitor_hash("salt", "site2", "1.2.3.4", "UA") != base
    assert hashing.visitor_hash("salt", "site", "5.6.7.8", "UA") != base
    assert hashing.visitor_hash("salt", "site", "1.2.3.4", "UA2") != base


# ── salt cache ─────────────────────────────────────────────────────────────


def test_salt_fetched_once_per_day():
    calls = []

    def fetch():
        calls.append(1)
        return "the-salt"

    assert salt_cache.get_salt(fetch) == "the-salt"
    assert salt_cache.get_salt(fetch) == "the-salt"
    assert len(calls) == 1


def test_salt_refetched_on_day_change(monkeypatch):
    from datetime import date

    salt_cache.get_salt(lambda: "day1")
    monkeypatch.setattr(salt_cache, "_today", lambda: date(2099, 1, 1))
    assert salt_cache.get_salt(lambda: "day2") == "day2"


# ── user agent ─────────────────────────────────────────────────────────────

CHROME = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
SAFARI = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
FIREFOX = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0"
EDGE = CHROME + " Edg/126.0.0.0"


def test_bot_detection():
    for bot in (
        "",
        "   ",
        "Mozilla/5.0 (compatible; Googlebot/2.1)",
        "python-requests/2.32.0",
        "curl/8.4.0",
        "Mozilla/5.0 HeadlessChrome/126.0.0.0",
        "Chrome-Lighthouse",
    ):
        assert ua_service.is_bot(bot), bot
    for real in (CHROME, SAFARI, FIREFOX, EDGE):
        assert not ua_service.is_bot(real), real


def test_browser_families():
    assert ua_service.browser(EDGE) == "edge"
    assert ua_service.browser(CHROME) == "chrome"
    assert ua_service.browser(SAFARI) == "safari"
    assert ua_service.browser(FIREFOX) == "firefox"
    assert ua_service.browser(CHROME + " OPR/110.0") == "other"
    assert (
        ua_service.browser(
            "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 CriOS/126.0 Mobile Safari/604.1"
        )
        == "chrome"
    )
    assert ua_service.browser("weird") == "other"


def test_device_buckets():
    assert ua_service.device(0) == "desktop"
    assert ua_service.device(-5) == "desktop"
    assert ua_service.device(390) == "mobile"
    assert ua_service.device(767) == "mobile"
    assert ua_service.device(768) == "tablet"
    assert ua_service.device(1023) == "tablet"
    assert ua_service.device(1024) == "desktop"
    assert ua_service.device(1920) == "desktop"


# ── client ip ──────────────────────────────────────────────────────────────


def test_client_ip_prefers_first_xff_entry():
    headers = {"x-forwarded-for": " 203.0.113.9 , 10.0.0.1, 172.16.0.1"}
    assert ip_service.client_ip(headers, "127.0.0.1") == "203.0.113.9"


def test_client_ip_fallback():
    assert ip_service.client_ip({}, "192.0.2.1") == "192.0.2.1"
    assert ip_service.client_ip({"x-forwarded-for": ""}, "192.0.2.1") == "192.0.2.1"
    assert ip_service.client_ip({"x-forwarded-for": " , "}, "192.0.2.1") == "192.0.2.1"
