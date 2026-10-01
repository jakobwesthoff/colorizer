# colorizer has to behave the same in every shell the README names. The bats
# suite runs once per shell, with TEST_SHELL naming the shell under test; the
# recipes below decide which shells and where.

# Shells for a run on this machine. Override per call, for example
# `just shells="bash /bin/bash zsh" test` to add macOS's bash 3.2.
shells := "bash zsh"

# The Docker matrix: one image per bash version, each run against its bash,
# zsh and busybox ash.
bash_images := "bash:3.2 bash:4.4 bash:5.2"
docker_shells := "bash zsh ash"

default: test

# Run the suite once per shell in `shells`
test:
    #!/usr/bin/env bash
    set -euo pipefail
    for shell in {{ shells }}; do
        just test-shell "${shell}"
    done

# Run the suite against one shell
test-shell shell:
    @echo "== {{ shell }}: $(command -v {{ shell }}) $({{ shell }} -c 'echo ${BASH_VERSION:-${ZSH_VERSION:-}}')"
    TEST_SHELL={{ shell }} bats tests/

# Build the test image for one bash image, such as `bash:3.2`
docker-build image:
    docker build --quiet --build-arg BASE={{ image }} -t colorizer-test:{{ replace(image, ":", "-") }} tests/docker

# Run the suite in the test image for one bash image
test-docker-image image: (docker-build image)
    docker run --rm -v "{{ justfile_directory() }}:/colorizer:ro" colorizer-test:{{ replace(image, ":", "-") }} just shells="{{ docker_shells }}" test

# Run the suite in every image of the Docker matrix
test-docker:
    #!/usr/bin/env bash
    set -euo pipefail
    for image in {{ bash_images }}; do
        just test-docker-image "${image}"
    done

# Run the suite on this machine and in the Docker matrix
test-all: test test-docker

# Check the test code with shellcheck
lint:
    shellcheck --shell=bats tests/*.bats
    shellcheck --shell=bash tests/helpers/*.bash
