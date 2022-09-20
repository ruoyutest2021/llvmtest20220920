ARG BASE_IMAGE_TAG
FROM buildpack-deps:${BASE_IMAGE_TAG}

ARG LLVM_VERSION
ENV LLVM_VERSION ${LLVM_VERSION}

ENV GPG_KEYS \
# 4096R/345AD05D 2015-01-20 Hans Wennborg <hans@chromium.org>
    B6C8F98282B944E3B0D5C2530FC3042E345AD05D \
# 4096R/86419D8A 2018-05-03 Tom Stellard <tstellar@redhat.com>
    474E22316ABF4785A88C6E8EA2C794A986419D8A \
# 3072R/45D59042 2022-08-05 Tobias Hieta <tobias@hieta.se>
    D574BD5D1D0E98895E3BF90044F2485E45D59042

RUN set -ex; \
    for key in $GPG_KEYS; do \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    done

RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates gnupg \
        build-essential make python3 zlib1g wget subversion unzip git; \
    rm -r /var/lib/apt/lists/*; \
    \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v3.24.2/cmake-3.24.2-linux-x86_64.tar.gz" -o 'cmake.tar.gz'; \
    echo "71a776b6a08135092b5beb00a603b60ca39f8231c01a0356e205e0b4631747d9 cmake.tar.gz" | \
        sha256sum -c; \
    tar -xf cmake.tar.gz -C /usr/local --strip-components=1; \
    rm cmake-tar.gz; \
    \
    curl -fL "https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip" -o 'ninja.zip'; \
    echo "d2fea9ff33b3ef353161ed906f260d565ca55b8ca0568fa07b1d2cab90a84a07 ninja.zip" | \
        sha256sum -c; \
    unzip ninja-linux.zip -d /usr/local/bin; \
    rm ninja-linux.zip; \
    \
    case "${LLVM_VERSION}" in \
        9.0.0 | 8.0.0 | 7.0.* | 6.* | 5.* | 4.* | 3.* | 2.* | 1.* ) \
            curl -fL "https://releases.llvm.org/${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz.sig" -o 'llvm.tar.xz.sig'; \
            curl -fL "https://releases.llvm.org/${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz" -o 'llvm.tar.xz'; \
            ;; \
        *) \
            curl -fL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz.sig" -o 'llvm.tar.xz.sig'; \
            curl -fL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz" -o 'llvm.tar.xz'; \
            ;; \
    esac; \
    gpg --batch --verify llvm.tar.xz.sig llvm.tar.xz; \
    mkdir -p /usr/src/llvm; \
    tar -xf llvm.tar.xz -C /usr/src/llvm --strip-components=1; \
    rm llvm.tar.xz*; \
    \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    \
    cmake -GNinja /usr/src/llvm; \
    ninja all; \
    \
    cd ..; \
    rm -rf "$dir" /usr/src/llvm;
