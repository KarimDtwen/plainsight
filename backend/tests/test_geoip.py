from services import geoip


class _FakeReader:
    def __init__(self, mapping):
        self._mapping = mapping

    def get(self, ip):
        return self._mapping.get(ip)

    def close(self):
        pass


def test_missing_database_returns_unknown(monkeypatch, tmp_path):
    monkeypatch.setattr(geoip, "GEOIP_DIR", str(tmp_path))
    geoip.reset_for_tests()
    assert geoip.country("8.8.8.8") == ""


def test_lookup_with_fake_reader(monkeypatch):
    geoip.reset_for_tests()
    monkeypatch.setattr(geoip, "_reader", _FakeReader({
        "8.8.8.8": {"country": {"iso_code": "US"}},
        "1.2.3.4": {},
    }))
    monkeypatch.setattr(geoip, "_load_attempted", True)
    assert geoip.country("8.8.8.8") == "US"
    assert geoip.country("1.2.3.4") == ""


def test_empty_ip_and_reader_errors(monkeypatch):
    geoip.reset_for_tests()

    class _Boom:
        def get(self, ip):
            raise ValueError("not an ip")

        def close(self):
            pass

    monkeypatch.setattr(geoip, "_reader", _Boom())
    monkeypatch.setattr(geoip, "_load_attempted", True)
    assert geoip.country("") == ""
    assert geoip.country("nonsense") == ""
