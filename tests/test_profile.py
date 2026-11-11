import pytest

from xsinject import ProfileError, resolve_profile


def make_profile(root, steamid):
    p = root / "Age of Empires 2 DE" / steamid / "profile"
    p.mkdir(parents=True)
    return p


def test_explicit_profile_wins_over_env_and_autodetect(tmp_path):
    make_profile(tmp_path, "111")
    explicit = tmp_path / "explicit"
    explicit.mkdir()
    env = {"XSINJECT_PROFILE": str(tmp_path / "from_env")}
    assert resolve_profile(explicit, environ=env, games_root=tmp_path) == explicit


def test_env_wins_over_autodetect(tmp_path):
    make_profile(tmp_path, "111")
    from_env = tmp_path / "from_env"
    from_env.mkdir()
    env = {"XSINJECT_PROFILE": str(from_env)}
    assert resolve_profile(None, environ=env, games_root=tmp_path) == from_env


def test_autodetects_the_single_steamid_profile(tmp_path):
    p = make_profile(tmp_path, "76561199655318799")
    assert resolve_profile(None, environ={}, games_root=tmp_path) == p


def test_autodetect_fails_with_no_profile(tmp_path):
    with pytest.raises(ProfileError, match="no profile"):
        resolve_profile(None, environ={}, games_root=tmp_path)


def test_autodetect_fails_with_several_profiles(tmp_path):
    make_profile(tmp_path, "111")
    make_profile(tmp_path, "222")
    with pytest.raises(ProfileError, match="--profile"):
        resolve_profile(None, environ={}, games_root=tmp_path)


def test_explicit_profile_must_exist(tmp_path):
    with pytest.raises(ProfileError, match="does not exist"):
        resolve_profile(tmp_path / "nope", environ={}, games_root=tmp_path)


def test_autodetect_skips_the_non_steam_0_folder_beside_a_real_one(tmp_path):
    make_profile(tmp_path, "0")
    p = make_profile(tmp_path, "76561199655318799")
    assert resolve_profile(None, environ={}, games_root=tmp_path) == p


def test_autodetect_uses_the_0_folder_when_it_is_the_only_one(tmp_path):
    p = make_profile(tmp_path, "0")
    assert resolve_profile(None, environ={}, games_root=tmp_path) == p
