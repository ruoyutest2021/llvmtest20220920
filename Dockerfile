ARG BASE_IMAGE_TAG
FROM buildpack-deps:${BASE_IMAGE_TAG}

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
    rm "cmake-${CMAKE_VERSION}"*

ARG LLVM_VERSION
ENV LLVM_VERSION ${LLVM_VERSION}

RUN set -ex; \
    \
    mkdir -p /usr/src/llvm-project; \
    git clone --branch="llvmorg-${LLVM_VERSION}" --depth=1 "https://github.com/llvm/llvm-project.git" /usr/src/llvm-project; \
    rm -rf /usr/src/llvm-project/.git; \
    \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS=all \
        -DLLVM_ENABLE_RUNTIMES=all \
        # https://github.com/llvm/llvm-project/issues/55517
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
        /usr/src/llvm-project/llvm \
    ; \
    cmake --build . -j "$(nproc)"; \
    cmake --build . --target install; \
    \
    cd ..; \
    rm -rf "$dir" /usr/src/llvm-project
