#!/usr/bin/env python3
"""Write the build matrix and version fields to $GITHUB_OUTPUT."""

import argparse
import importlib.machinery
import importlib.util
import json
import os
import sys

from ci.build_matrix import build_matrix, docker_matrix

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_genenv():
    loader = importlib.machinery.SourceFileLoader(
        "genenv_mod", os.path.join(REPO_ROOT, "genenv")
    )
    spec = importlib.util.spec_from_loader("genenv_mod", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    try:
        env = load_genenv().compute_env(args.version)
    except ValueError as exc:
        print("error: {}".format(exc), file=sys.stderr)
        return 1

    fields = {
        "version": env["VERSION"],
        "releasever": env["RELEASEVER"],
        "package_name": env["PACKAGE_NAME"],
        "short_version": env["SHORT_VERSION"],
        # json.dumps with the default separators emits no newlines, which
        # matters because GITHUB_OUTPUT is parsed line by line.
        "matrix": json.dumps(build_matrix()),
        "docker_matrix": json.dumps(docker_matrix()),
        "s3_prefix": ".staging/{}/".format(args.version) if args.dry_run else "",
    }

    with open(os.environ["GITHUB_OUTPUT"], "a") as handle:
        for key, value in fields.items():
            handle.write("{}={}\n".format(key, value))
    return 0


if __name__ == "__main__":
    sys.exit(main())
