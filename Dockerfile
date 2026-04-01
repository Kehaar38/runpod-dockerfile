# ===== ビルド用ステージ =====
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404 AS builder

# 非対話化
ENV DEBIAN_FRONTEND=noninteractive

# ビルドに必要な最低限のパッケージを入れる
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    curl \
    libcurl4-openssl-dev

# llama.cpp を取得して llama-server のみビルド
WORKDIR /workspace
RUN git clone --depth=1 https://github.com/ggml-org/llama.cpp.git
WORKDIR /workspace/llama.cpp

RUN cmake -B build \
    -DBUILD_SHARED_LIBS=OFF \
	-DGGML_CUDA=ON \
	-DGGML_NATIVE=OFF \
	-DLLAMA_CURL=ON \
	-DLLAMA_BUILD_BORINGSSL=ON \
	-DLLAMA_BUILD_LIBRESSL=ON \
	-DLLAMA_OPENSSL=ON

RUN cmake --build build --config Release -t llama-server -j"$(nproc)"


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
COPY --from=builder /workspace/llama.cpp/build/bin/llama-server /usr/local/bin/

# ライブラリキャッシュを更新
RUN ldconfig

WORKDIR /workspace

# APIポート
EXPOSE 10000

# 既定では軽いモデルを起動
CMD ["llama-server", "-hf", "unsloth/Qwen3.5-0.8B-GGUF:Q4_K_M", "--host", "0.0.0.0", "--port", "10000", "--ctx-size", "65536",]
