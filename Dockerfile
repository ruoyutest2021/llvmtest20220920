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

ARG CMAKE_VERSION
ENV CMAKE_VERSION ${CMAKE_VERSION}

RUN set -ex; \
    \
    # 4096R/7BFB4EDA 2010-02-16 Brad King
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys CBA23971357C2E6590D9EFD3EC8FEF3A7BFB4EDA; \
    \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc" -O; \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt" -O; \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -O; \
    gpg --batch --verify "cmake-${CMAKE_VERSION}-SHA-256.txt.asc" "cmake-${CMAKE_VERSION}-SHA-256.txt"; \
    sha256sum -c --ignore-missing "cmake-${CMAKE_VERSION}-SHA-256.txt"; \
    tar -xf "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -C /usr/local --strip-components=1; \
    rm "cmake-${CMAKE_VERSION}-SHA-256.txt"* "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"

ARG LLVM_VERSION
ENV LLVM_VERSION ${LLVM_VERSION}

RUN set -ex; \
    \
    mkdir -p /usr/src/llvm; \
    git clone --branch="llvmorg-${LLVM_VERSION}" --depth=1 "https://github.com/llvm/llvm-project.git" /usr/src/llvm; \
    \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    \
    cmake \
        -DLLVM_ENABLE_PROJECTS=clang \
        -DCMAKE_BUILD_TYPE=Release \
        /usr/src/llvm/llvm \
    ; \
    cmake --build . -j "$(nproc)"; \
    cmake --build . --target install; \
    \
    cd ..; \
    rm -rf "$dir" /usr/src/llvm
