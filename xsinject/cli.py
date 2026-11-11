"""Thin CLI over the driver API: prints the result JSON, exits 0 only on OK."""

import argparse
import json
import sys

from . import driver


def _add_wait_options(parser):
    parser.add_argument("--profile", help="profile folder (default: $XSINJECT_PROFILE, then auto-detect)")
    parser.add_argument("--map", help="stem of the .xsdat that holds the response (e.g. default1)")
    parser.add_argument("--timeout", type=float, default=driver.DEFAULT_TIMEOUT, help="seconds to wait for a response")
    parser.add_argument("--poll", type=float, default=driver.DEFAULT_POLL, help="seconds between response checks")


def _add_send_options(parser):
    _add_wait_options(parser)
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

    fetch = sub.add_parser("fetch", help="decode the current response against the last request sent, sending nothing")
    _add_wait_options(fetch)

    encode = sub.add_parser("encode", help="print a request's bytes to stdout without sending it")
    encode.add_argument("request", help="file holding the request JSON, or - for stdin")
    encode.add_argument("--profile", help="profile folder whose request file gives the next request id "
                        "(default: $XSINJECT_PROFILE, then auto-detect; id 1 when none is found)")
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


def _encode(args):
    """Writes the request bytes to stdout and returns 0, or returns the Invalid result."""
    calls, result = _read_request(args.request)
    if result is not None:
        return result
    try:
        data = driver.encode(calls, profile=args.profile)
    except driver.InvalidRequest as e:
        return e.result
    sys.stdout.flush()
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()
    return None


def main(argv=None):
    args = _parser().parse_args(argv)
    if args.command == "encode":
        result = _encode(args)
        if result is None:
            return 0
        print(json.dumps(result, indent=2))
        return 1
    options = dict(profile=args.profile, map=args.map, timeout=args.timeout, poll=args.poll)
    if args.command == "fetch":
        result = driver.fetch(**options)
    else:
        options["lock_timeout"] = args.lock_timeout  # only sends take the request file
        if args.command == "ping":
            result = driver.ping(**options)
        else:
            calls, result = _read_request(args.request)
            if result is None:
                result = driver.run(calls, **options)
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "OK" else 1
