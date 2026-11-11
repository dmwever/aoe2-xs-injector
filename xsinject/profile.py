"""Finding the AoE2:DE profile folder that holds the .xsdat files."""

import os
from pathlib import Path

ENV_VAR = "XSINJECT_PROFILE"
GAME_DIR = "Age of Empires 2 DE"


class ProfileError(Exception):
    pass


def default_games_root():
    return Path.home() / "Games"


def resolve_profile(explicit=None, *, environ=None, games_root=None):
    """`explicit`, then $XSINJECT_PROFILE, then the single <steamid>/profile under games_root."""
    environ = os.environ if environ is None else environ
    if explicit is None and environ.get(ENV_VAR):
        explicit = environ[ENV_VAR]
    if explicit is not None:
        path = Path(explicit)
        if not path.is_dir():
            raise ProfileError(f"profile folder {path} does not exist")
        return path

    base = Path(games_root if games_root is not None else default_games_root()) / GAME_DIR
    found = sorted(p for p in base.glob("*/profile") if p.is_dir())
    if len(found) > 1:
        # "0" is the game's non-Steam folder; a real <steamid> beside it is the one in use.
        found = [p for p in found if p.parent.name != "0"]
    if not found:
        raise ProfileError(f"no profile folder found under {base}; pass --profile or set {ENV_VAR}")
    if len(found) > 1:
        names = ", ".join(str(p) for p in found)
        raise ProfileError(f"several profile folders found ({names}); pass --profile or set {ENV_VAR}")
    return found[0]
