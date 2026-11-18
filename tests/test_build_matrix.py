from ci.build_matrix import build_matrix, docker_matrix


def job(name, arch):
    return next(
        j for j in build_matrix()["include"] if j["name"] == name and j["arch"] == arch
    )


def test_matrix_is_four_distros_times_two_arches():
    jobs = build_matrix()["include"]
    assert sorted((j["name"], j["arch"]) for j in jobs) == [
        ("alpine3.14", "amd64"),
        ("alpine3.14", "arm64"),
        ("alpine3.15", "amd64"),
        ("alpine3.15", "arm64"),
        ("jammy", "amd64"),
        ("jammy", "arm64"),
        ("noble", "amd64"),
        ("noble", "arm64"),
    ]


def test_noble_arm64_job_fields():
    j = job("noble", "arm64")
    assert j["runner"] == "ubuntu-24.04-arm"
    assert j["image"] == "charlesportwoodii/ubuntu:24.04-build"
    assert j["packaging"] == "debian"
    assert j["build_os"] == "Ubuntu"
    assert j["build_os_version"] == "24.04"
    assert j["artifact_dir"] == "build/deb/noble"
    assert j["s3_key"] == "deb/noble"
    assert "luajit-2.1" in j["prebuild"]


def test_jammy_uses_2204_image():
    j = job("jammy", "amd64")
    assert j["image"] == "charlesportwoodii/ubuntu:22.04-build"
    assert j["runner"] == "ubuntu-24.04"


def test_alpine315_paths_per_arch():
    amd = job("alpine3.15", "amd64")
    arm = job("alpine3.15", "arm64")
    assert amd["artifact_dir"] == "build/alpine/v3.15/main/x86_64"
    assert amd["s3_key"] == "alpine/v3.15/main/x86_64"
    assert arm["artifact_dir"] == "build/alpine/v3.15/main/aarch64"
    assert amd["packaging"] == "alpine"
    assert amd["image"] == "charlesportwoodii/alpine:3.15-build"
    assert "luajit-2.1" in amd["prebuild"]


def test_docker_matrix_is_both_arches():
    assert docker_matrix() == {
        "include": [
            {"arch": "amd64", "runner": "ubuntu-24.04"},
            {"arch": "arm64", "runner": "ubuntu-24.04-arm"},
        ]
    }
