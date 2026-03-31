FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

LABEL org.opencontainers.image.source="https://github.com/kehaar38/runpod-dockerfile"

ENV DEBIAN_FRONTEND=noninteractive \
    HF_HOME=/workspace/.cache/huggingface \
    HF_HUB_CACHE=/workspace/.cache/huggingface/hub

RUN mkdir -p /workspace/.cache/huggingface/hub

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ninja-build \
    libcurl4-openssl-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN git clone --depth=1 https://github.com/ggml-org/llama.cpp.git
WORKDIR /workspace/llama.cpp

RUN cmake -B build -G Ninja \
    -DGGML_CUDA=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_TESTS=OFF

RUN cmake --build build -j"$(nproc)"

RUN mkdir -p /opt/llama/bin && \
    cp -a build/bin/. /opt/llama/bin/

ENV LD_LIBRARY_PATH=/opt/llama/bin:${LD_LIBRARY_PATH}

WORKDIR /workspace
RUN rm -rf /workspace/llama.cpp

EXPOSE 8888 10000

RUN jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root >/workspace/jupyter.log 2>&1 &

CMD ["/opt/llama/bin/llama-server", "-hf", "unsloth/Qwen3.5-0.8B-GGUF:UD-Q4_K_M", "--port", "10000", "--host", "0.0.0.0", "--ctx-size", "65536"]
