import re
from pathlib import Path

from conftest import MAGIC

CORE = Path(__file__).resolve().parent.parent / "xs" / "xsinject.xs"


def _xs_const(name):
    found = re.search(rf"const int {name} = (\d+);", CORE.read_text())
    assert found, name
    return int(found.group(1))


def test_xs_core_uses_the_same_magic_as_the_driver():
    assert _xs_const("cXsInjectMagic") == MAGIC


def test_xs_core_uses_the_same_too_large_code_and_write_limit_as_the_driver():
    from xsinject import wire

    assert _xs_const("cXsInjectTooLarge") == wire.TOO_LARGE
    assert wire.REQUEST_STATUS[wire.TOO_LARGE] == "TooLarge"
    assert _xs_const("cXsInjectWriteLimit") == wire.WRITE_LIMIT
