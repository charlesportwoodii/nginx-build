import importlib.machinery
import importlib.util
import os

import pytest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_genenv():
    loader = importlib.machinery.SourceFileLoader(
        "genenv_mod", os.path.join(REPO_ROOT, "genenv")
    )
    spec = importlib.util.spec_from_loader("genenv_mod", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


genenv = load_genenv()


def test_parses_mainline_tag():
    assert genenv.compute_env("1.29.3-1") == {
        "VERSION": "1.29.3",
        "RELEASEVER": "1",
        "PACKAGE_NAME": "nginx-mainline",
        "SHORT_VERSION": "1.29",
    }


def test_even_minor_is_stable():
    assert genenv.compute_env("1.30.0-1")["PACKAGE_NAME"] == "nginx"


def test_parses_second_revision():
    assert genenv.compute_env("1.27.4-2")["RELEASEVER"] == "2"


def test_version_without_revision_defaults_to_one():
    assert genenv.compute_env("1.29.3")["RELEASEVER"] == "1"


def test_rejects_non_semver():
    with pytest.raises(ValueError):
        genenv.compute_env("latest")


def test_rejects_empty_version():
    with pytest.raises(ValueError):
        genenv.compute_env("")


def test_writes_envs_in_stable_order(tmp_path):
    target = tmp_path / ".envs"
    genenv.write_envs("1.29.3-1", str(target))
    assert target.read_text().splitlines() == [
        "VERSION=1.29.3",
        "RELEASEVER=1",
        "PACKAGE_NAME=nginx-mainline",
        "SHORT_VERSION=1.29",
    ]
