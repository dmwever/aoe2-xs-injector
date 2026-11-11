"""Thin CLI over the driver API: prints the result JSON, exits 0 only on OK."""

import argparse
import json
import sys

from . import driver


def _add_send_options(parser):
    parser.add_argument("--profile", help="profile folder (default: $XSINJECT_PROFILE, then auto-detect)")
    parser.add_argument("--map", help="stem of the .xsdat that holds the response (e.g. default1)")
    parser.add_argument("--timeout", type=float, default=driver.DEFAULT_TIMEOUT, help="seconds to wait for a response")
    parser.add_argument("--poll", type=float, default=driver.DEFAULT_POLL, help="seconds between response checks")
    parser.add_argument("--lock-timeout", type=float, default=driver.DEFAULT_LOCK_TIMEOUT,
                        help="seconds to retry while the game holds the request file")


def _parser():
    parser = argparse.ArgumentParser(prog="xsinject", description="Drive the XS function injector in a live match.")
    sub = parser.add_subparsers(dest="command", required=True)

    ping = sub.add_parser("ping", help="send a zero-call request to check the module is live")
    _add_send_options(ping)

    run = sub.add_parser("run", help='send a request: a JSON array of {"fn": <name>, "args": [...]} calls')
    run.add_argument("request", help="file holding the request JSON, or - for stdin")
    _add_send_options(run)
    return parser


def _read_request(source):
    """The parsed request JSON, or an Invalid result when it can't be read or parsed."""
    try:
        if source == "-":
            text = sys.stdin.read()
        else:
            with open(source, encoding="utf-8") as f:
                text = f.read()
        return json.loads(text), None
    except (OSError, ValueError) as e:
        where = "stdin" if source == "-" else source
        return None, driver.invalid(f"could not read the request from {where}: {e}")


def main(argv=None):
    args = _parser().parse_args(argv)
    options = dict(profile=args.profile, map=args.map, timeout=args.timeout, poll=args.poll,
                   lock_timeout=args.lock_timeout)
    if args.command == "ping":
        result = driver.ping(**options)
    else:
        calls, result = _read_request(args.request)
        if result is None:
            result = driver.run(calls, **options)
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "OK" else 1
