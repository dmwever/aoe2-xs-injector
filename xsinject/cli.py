"""Thin CLI over the driver API: prints the result JSON, exits 0 only on OK."""

import argparse
import json

from . import driver


def _parser():
    parser = argparse.ArgumentParser(prog="xsinject", description="Drive the XS function injector in a live match.")
    sub = parser.add_subparsers(dest="command", required=True)

    ping = sub.add_parser("ping", help="send a zero-call request to check the module is live")
    ping.add_argument("--profile", help="profile folder (default: $XSINJECT_PROFILE, then auto-detect)")
    ping.add_argument("--map", help="stem of the .xsdat that holds the response (e.g. default1)")
    ping.add_argument("--timeout", type=float, default=driver.DEFAULT_TIMEOUT, help="seconds to wait for a response")
    ping.add_argument("--poll", type=float, default=driver.DEFAULT_POLL, help="seconds between response checks")
    ping.add_argument("--lock-timeout", type=float, default=driver.DEFAULT_LOCK_TIMEOUT,
                      help="seconds to retry while the game holds the request file")
    return parser


def main(argv=None):
    args = _parser().parse_args(argv)
    result = driver.ping(
        profile=args.profile, map=args.map, timeout=args.timeout, poll=args.poll, lock_timeout=args.lock_timeout,
    )
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "OK" else 1

