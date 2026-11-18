"""Single source of truth for which distros and arches nginx is built on.

Every nginx version builds on every distro, so unlike php-fpm-build there is
no per-version filter. Adding or dropping a distro is a change to DISTROS
and nothing else.
"""

RUNNERS = {"amd64": "ubuntu-24.04", "arm64": "ubuntu-24.04-arm"}

# Alpine names the architectures differently from Docker/GitHub.
ALPINE_ARCH = {"amd64": "x86_64", "arm64": "aarch64"}

ARCHES = ["amd64", "arm64"]

_DEBIAN_PREBUILD = "apt update && apt install -y --reinstall ca-certificates luajit-2.1"
# `|| true` was arm64-only under Drone. It is kept on both arches so one
# entry serves both; a real luajit problem still fails the compile.
_ALPINE_PREBUILD = "apk add --no-cache luajit-2.1 || true"

DISTROS = [
    {
        "name": "jammy",
        "packaging": "debian",
        "image": "charlesportwoodii/ubuntu:22.04-build",
        "build_os": "Ubuntu",
        "build_os_version": "22.04",
        "prebuild": _DEBIAN_PREBUILD,
    },
    {
        "name": "noble",
        "packaging": "debian",
        "image": "charlesportwoodii/ubuntu:24.04-build",
        "build_os": "Ubuntu",
        "build_os_version": "24.04",
        "prebuild": _DEBIAN_PREBUILD,
    },
    {
        "name": "alpine3.14",
        "packaging": "alpine",
        "image": "charlesportwoodii/alpine:3.14-build",
        "build_os": "Alpine",
        "build_os_version": "3.14",
        "prebuild": _ALPINE_PREBUILD,
    },
    {
        "name": "alpine3.15",
        "packaging": "alpine",
        "image": "charlesportwoodii/alpine:3.15-build",
        "build_os": "Alpine",
        "build_os_version": "3.15",
        "prebuild": _ALPINE_PREBUILD,
    },
]


def _artifact_dir(distro, arch):
    if distro["packaging"] == "alpine":
        return "build/alpine/v{}/main/{}".format(
            distro["build_os_version"], ALPINE_ARCH[arch]
        )
    return "build/deb/{}".format(distro["name"])


def _job(distro, arch):
    artifact_dir = _artifact_dir(distro, arch)
    return {
        "name": distro["name"],
        "arch": arch,
        "runner": RUNNERS[arch],
        "image": distro["image"],
        "packaging": distro["packaging"],
        "build_os": distro["build_os"],
        "build_os_version": distro["build_os_version"],
        "prebuild": distro["prebuild"],
        "artifact_dir": artifact_dir,
        # Bucket keys drop the leading "build/" so the layout matches what
        # the Drone s3-sync of ./build/ produced.
        "s3_key": artifact_dir[len("build/"):],
    }


def build_matrix():
    """Matrix for the compile/package jobs: one entry per distro per arch."""
    return {"include": [_job(d, arch) for d in DISTROS for arch in ARCHES]}


def docker_matrix():
    """Matrix for the image jobs: one entry per arch."""
    return {"include": [{"arch": arch, "runner": RUNNERS[arch]} for arch in ARCHES]}
