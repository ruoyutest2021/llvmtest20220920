ARG BASE_IMAGE_TAG
FROM buildpack-deps:${BASE_IMAGE_TAG}

ARG LLVM_VERSION
ENV LLVM_VERSION ${LLVM_VERSION}

RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        gnupg \
        lsb-release \
        software-properties-common \
        wget \
    ; \
    rm -r /var/lib/apt/lists/*; \
    \
    wget -O- https://apt.llvm.org/llvm.sh | bash -s "${LLVM_VERSION}" all
