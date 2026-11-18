import os

import yaml

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKFLOW = os.path.join(REPO_ROOT, ".github", "workflows", "release.yml")


def load():
    with open(WORKFLOW) as handle:
        return yaml.safe_load(handle)


def test_releases_share_one_concurrency_group():
    """Stable and mainline releases must not run at the same time.

    trigger_drone.sh adopts any in-flight Drone index refresh. Two parallel
    releases could adopt each other's refresh before their own packages are
    uploaded.
    """
    assert load()["concurrency"]["group"] == "release"


def test_failed_prebuild_stops_the_build():
    """Drone failed the step when `apt update` failed; `;` would hide it."""
    steps = load()["jobs"]["build"]["steps"]
    compile_step = next(s for s in steps if s.get("name") == "Compile and package")
    assert '"${{ matrix.prebuild }} && make build $target"' in compile_step["run"]
