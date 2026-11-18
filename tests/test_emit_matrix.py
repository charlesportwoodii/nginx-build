import json
import os
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def invoke(version, dry_run, tmp_path):
    output = tmp_path / "gh_output"
    output.write_text("")
    env = dict(os.environ, GITHUB_OUTPUT=str(output), PYTHONPATH=REPO_ROOT)
    # Invoked as a module, not a path: `python ci/emit_matrix.py` puts ci/ on
    # sys.path instead of the repo root and the ci.build_matrix import fails.
    proc = subprocess.run(
        [sys.executable, "-m", "ci.emit_matrix", "--version", version]
        + (["--dry-run"] if dry_run else []),
        cwd=REPO_ROOT,
        env=env,
    )
    return proc, output


def run(version, dry_run, tmp_path):
    proc, output = invoke(version, dry_run, tmp_path)
    assert proc.returncode == 0
    result = {}
    for line in output.read_text().splitlines():
        key, _, value = line.partition("=")
        result[key] = value
    return result


def test_emits_version_fields(tmp_path):
    out = run("1.29.3-1", False, tmp_path)
    assert out["version"] == "1.29.3"
    assert out["releasever"] == "1"
    assert out["package_name"] == "nginx-mainline"
    assert out["short_version"] == "1.29"


def test_emits_parseable_matrix(tmp_path):
    out = run("1.29.3-1", False, tmp_path)
    assert len(json.loads(out["matrix"])["include"]) == 8
    assert len(json.loads(out["docker_matrix"])["include"]) == 2


def test_real_release_has_empty_s3_prefix(tmp_path):
    assert run("1.29.3-1", False, tmp_path)["s3_prefix"] == ""


def test_dry_run_uses_staging_prefix(tmp_path):
    assert run("1.29.3-1", True, tmp_path)["s3_prefix"] == ".staging/1.29.3-1/"


def test_matrix_json_is_single_line(tmp_path):
    """GITHUB_OUTPUT is line-based; embedded newlines would corrupt it."""
    out = run("1.29.3-1", False, tmp_path)
    assert "\n" not in out["matrix"]


def test_invalid_version_fails_without_output(tmp_path):
    proc, output = invoke("latest", False, tmp_path)
    assert proc.returncode != 0
    assert output.read_text() == ""
