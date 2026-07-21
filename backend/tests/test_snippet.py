def test_snippet_served_with_headers(client):
    resp = client.get("/js/script.js")
    assert resp.status_code == 200
    assert resp.headers["access-control-allow-origin"] == "*"
    assert resp.headers["cache-control"] == "public, max-age=86400"
    assert "javascript" in resp.headers["content-type"]


def test_snippet_contract(client):
    body = client.get("/js/script.js").text
    # The behaviors the backend + docs promise:
    for marker in ("sendBeacon", "pushState", "popstate", "data-site",
                   "doNotTrack", "/collect"):
        assert marker in body, f"snippet lost its {marker} behavior"
    assert len(body.encode()) < 4096, "snippet must stay tiny (~50 lines)"
    assert "console.log" not in body
