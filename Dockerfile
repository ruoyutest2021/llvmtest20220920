ARG BASE_IMAGE_TAG
FROM buildpack-deps:${BASE_IMAGE_TAG}

ARG PYTHON_VERSION
ENV PYTHON_VERSION ${PYTHON_VERSION}

RUN set -ex; \
    \
    # 4096R/AA65421D 2014-11-02 Ned Deily (Python release signing key) <nad@python.org>
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D; \
    # 4096R/10250568 2015-05-11 \xc5\x81ukasz Langa (GPG langa.pl) <lukasz@langa.pl>
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys E3FF2839C048B25C084DEBE9B26995E310250568; \
    # 4096R/D684696D 2018-03-30 Pablo Galindo Salgado <pablogsal@gmail.com>
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys A035C8C19219BA821ECEA86B64E628F8D684696D; \
    \
    curl -fL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz.asc" -o 'python.tar.xz.asc'; \
    curl -fL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz" -o 'python.tar.xz'; \
    gpg --batch --verify python.tar.xz.asc python.tar.xz; \
    mkdir -p /usr/src/python; \
    tar -xf python.tar.xz -C /usr/src/python --strip-components=1; \
    rm python.tar.xz*; \
    \
	cd /usr/src/python; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
        --with-lto \
		--with-system-expat \
		--without-ensurepip \
	; \
    make -j "$(nproc)"; \
    make install; \
    \
    rm -rf /usr/src/python

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
    curl -fL "https://github.com/Kitware/CMake/releases/download/v3.24.2/cmake-3.24.2-linux-x86_64.tar.gz" -o 'cmake.tar.gz'; \
    echo "71a776b6a08135092b5beb00a603b60ca39f8231c01a0356e205e0b4631747d9 cmake.tar.gz" | \
        sha256sum -c; \
    tar -xf cmake.tar.gz -C /usr/local --strip-components=1; \
    rm cmake.tar.gz; \
    \
    mkdir -p /usr/src/llvm; \
    git clone -b "llvmorg-${LLVM_VERSION}" --single-branch "https://github.com/llvm/llvm-project.git" /usr/src/llvm; \
    \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        /usr/src/llvm \
    ; \
    cmake --build . -j "$(nproc)"; \
    cmake --build . --target install; \
    \
    cd ..; \
    rm -rf "$dir" /usr/src/llvm
