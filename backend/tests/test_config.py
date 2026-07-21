import pytest

from config import ConfigurationError, Settings

BASE_TEST_ENV = {
    "APP_ENV": "test",
}

PROD_ENV = {
    "APP_ENV": "production",
    "SUPABASE_URL": "https://example.supabase.co",
    "SUPABASE_SERVICE_ROLE_KEY": "real-key",
    "ADMIN_PASSWORD": "hunter2-but-long",
    "JWT_SECRET": "a-long-random-secret",
    "ALLOWED_ORIGINS": "https://plainsight-app.web.app",
}


def test_test_env_needs_no_secrets():
    settings = Settings.from_env(BASE_TEST_ENV)
    assert settings.environment == "test"
    assert not settings.is_production
    assert settings.jwt_ttl_hours == 168


def test_invalid_app_env_rejected():
    with pytest.raises(ConfigurationError, match="APP_ENV"):
        Settings.from_env({"APP_ENV": "staging"})


def test_production_fail_fast_lists_missing_names_only():
    with pytest.raises(ConfigurationError) as excinfo:
        Settings.from_env({"APP_ENV": "production"})
    message = str(excinfo.value)
    for name in (
        "ADMIN_PASSWORD",
        "ALLOWED_ORIGINS",
        "JWT_SECRET",
        "SUPABASE_SERVICE_ROLE_KEY",
    ):
        assert name in message


def test_production_with_all_vars_constructs():
    settings = Settings.from_env(PROD_ENV)
    assert settings.is_production
    assert settings.allowed_origins == ("https://plainsight-app.web.app",)
    assert settings.local_origin_regex is None


def test_secrets_never_appear_in_repr():
    settings = Settings.from_env(PROD_ENV)
    rendered = repr(settings)
    assert "real-key" not in rendered
    assert "hunter2-but-long" not in rendered
    assert "a-long-random-secret" not in rendered


def test_origins_parsed_and_validated():
    env = dict(PROD_ENV)
    env["ALLOWED_ORIGINS"] = "https://a.example.com, https://b.example.com/"
    settings = Settings.from_env(env)
    assert settings.allowed_origins == (
        "https://a.example.com",
        "https://b.example.com",
    )

    env["ALLOWED_ORIGINS"] = "not-a-url"
    with pytest.raises(ConfigurationError, match="ALLOWED_ORIGINS"):
        Settings.from_env(env)


def test_jwt_ttl_must_be_positive_int():
    env = dict(BASE_TEST_ENV)
    for bad in ("0", "-3", "soon"):
        env["JWT_TTL_HOURS"] = bad
        with pytest.raises(ConfigurationError, match="JWT_TTL_HOURS"):
            Settings.from_env(env)


def test_localhost_regex_outside_production():
    settings = Settings.from_env(BASE_TEST_ENV)
    assert settings.local_origin_regex is not None
    assert "localhost" in settings.local_origin_regex
