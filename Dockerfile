# ===== ビルド用ステージ =====
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404 AS builder

LABEL org.opencontainers.image.source="https://github.com/kehaar38/runpod-dockerfile"

# 非対話化と、ビルド時にだけ使う CUDA stub の場所
ENV DEBIAN_FRONTEND=noninteractive \
    CUDA_STUB=/usr/local/cuda/lib64/stubs

# ビルドに必要な最低限のパッケージを入れる
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ninja-build \
    libcurl4-openssl-dev \
 && rm -rf /var/lib/apt/lists/*

# build中は本物のGPUドライバが見えないことがあるので stub を使う
RUN ln -sf ${CUDA_STUB}/libcuda.so ${CUDA_STUB}/libcuda.so.1 && \
    echo "${CUDA_STUB}" > /etc/ld.so.conf.d/cuda-stubs.conf && \
    ldconfig

# ビルド時だけ stub を検索パスに追加
ENV LIBRARY_PATH=${CUDA_STUB}:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${CUDA_STUB}:${LD_LIBRARY_PATH}

# llama.cpp を取得して server のみビルド
WORKDIR /workspace
RUN git clone --depth=1 https://github.com/ggml-org/llama.cpp.git
WORKDIR /workspace/llama.cpp

RUN cmake -B build -G Ninja \
    -DGGML_CUDA=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_TESTS=OFF

RUN cmake --build build -j"$(nproc)"


# ===== 実行用ステージ =====
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Hugging Face のキャッシュを /workspace 側に置く
ENV DEBIAN_FRONTEND=noninteractive \
    HF_HOME=/workspace/.cache/huggingface \
    HF_HUB_CACHE=/workspace/.cache/huggingface/hub

RUN mkdir -p /workspace/.cache/huggingface/hub

# 実行時に必要なライブラリだけ入れる
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
 && rm -rf /var/lib/apt/lists/*

# 実行ファイルをコピー
COPY --from=builder /workspace/llama.cpp/build/bin/* /usr/local/bin/

# ライブラリキャッシュを更新
RUN ldconfig

WORKDIR /workspace

# APIポート
EXPOSE 10000

# 既定では軽いモデルを起動
# GPU優先、CPUスレッド控えめ、並列1で扱いやすい設定
CMD ["llama-server", "-hf", "unsloth/Qwen3.5-0.8B-GGUF:Q4_K_M", "--host", "0.0.0.0", "--port", "10000", "--ctx-size", "65536", "--n-gpu-layers", "999"]
