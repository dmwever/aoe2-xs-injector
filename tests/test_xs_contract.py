import re
from pathlib import Path

from conftest import MAGIC

CORE = Path(__file__).resolve().parent.parent / "xs" / "xsinject.xs"


def test_xs_core_uses_the_same_magic_as_the_driver():
    found = re.search(r"const int cXsInjectMagic = (\d+);", CORE.read_text())
    assert found and int(found.group(1)) == MAGIC
