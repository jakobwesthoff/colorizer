# The test image for one bash version.
#
# BASE is one of the official `bash` images, which build that bash version on
# Alpine. Alpine's /bin/ash is busybox, so the image covers bash and busybox
# ash; zsh, bats, just and util-linux's `script` (for tests that need a
# terminal) come from Alpine's packages. The repository is
# mounted at /colorizer when the tests run, so the image holds tools only.
ARG BASE=bash:5.2
FROM ${BASE}

RUN apk add --no-cache zsh bats just util-linux-misc

WORKDIR /colorizer
