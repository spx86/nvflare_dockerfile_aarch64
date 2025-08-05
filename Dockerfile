FROM python:3.11.13-slim-bullseye as builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    build-essential \
    cmake \
    wget \
    unzip \
    git \
    autoconf \
    libtool \
    pkg-config \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade pip setuptools wheel packaging nvflare==2.6.1 -i https://pypi.tuna.tsinghua.edu.cn/simple

WORKDIR /workspace

RUN mkdir -p /workspace/tools
RUN cd /workspace/tools && \
    wget https://github.com/bazelbuild/bazel/releases/download/8.3.1/bazel-8.3.1-linux-arm64 && \
    chmod +x bazel-8.3.1-linux-arm64 && \
    ln -s /workspace/tools/bazel-8.3.1-linux-arm64 /usr/local/bin/bazel

RUN mkdir -p /workspace/3rdParty
RUN git clone --depth=1 https://github.com/OpenMined/PSI.git -b v2.0.6 /workspace/3rdParty/PSI && \
    cd /workspace/3rdParty/PSI && \
    bazel build -c opt //private_set_intersection/python:wheel && \
    pip install ./bazel-bin/private_set_intersection/python/*.whl

RUN git clone --depth=1 https://github.com/OpenMined/TenSEAL.git -b v0.3.15 /workspace/3rdParty/TenSEAL && \
    cd /workspace/3rdParty/TenSEAL && \
    pip install .

RUN git clone --depth=1 https://github.com/grpc/grpc.git -b v1.74.0 /workspace/3rdParty/grpc && \
    cd /workspace/3rdParty/grpc && \
    git submodule update --init --recursive --depth 1 

RUN cd /workspace/3rdParty/grpc && \
    mkdir -p cmake/build && \
    cd cmake/build && \
    cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_CXX_STANDARD=17  ../.. && \
    make -j$(nproc) && \
    make install

RUN git clone --depth=1 https://github.com/dmlc/xgboost.git -b v3.0.2 /workspace/3rdParty/xgboost && \
    cd /workspace/3rdParty/xgboost && \
    git submodule update --init --recursive && \
    cmake -B build -S . -DPLUGIN_FEDERATED=ON -GNinja && \
    cd build && ninja && \
    cd ../python-package/ && \
    pip install .

RUN git clone https://github.com/NVIDIA/NVFlare.git -b 2.6.1 /workspace/NVFlare
FROM python:3.11.13-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 && \ 
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /workspace/NVFlare /workspace/NVFlare

CMD ["/bin/bash"]

