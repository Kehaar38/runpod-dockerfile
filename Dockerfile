FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

LABEL org.opencontainers.image.source="https://github.com/kehaar38/runpod-dockerfile"

ENV DEBIAN_FRONTEND=noninteractive \
    HF_HOME=/workspace/.cache/huggingface \
    HF_HUB_CACHE=/workspace/.cache/huggingface/hub \
    CUDA_STUB=/usr/local/cuda/lib64/stubs

RUN mkdir -p /workspace/.cache/huggingface/hub

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    ninja-build \
    libcurl4-openssl-dev \
 && rm -rf /var/lib/apt/lists/*

# build 時に libcuda.so.1 を見つけられるように CUDA stub を使う
RUN ln -sf ${CUDA_STUB}/libcuda.so ${CUDA_STUB}/libcuda.so.1 && \
    echo "${CUDA_STUB}" > /etc/ld.so.conf.d/cuda-stubs.conf && \
    ldconfig

ENV LIBRARY_PATH=${CUDA_STUB}:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${CUDA_STUB}:${LD_LIBRARY_PATH}

WORKDIR /workspace
RUN git clone --depth=1 https://github.com/ggml-org/llama.cpp.git
WORKDIR /workspace/llama.cpp

RUN cmake -B build -G Ninja \
    -DGGML_CUDA=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_TESTS=OFF

RUN cmake --build build -j1

RUN cp build/bin/llama-server /usr/local/bin/
WORKDIR /workspace
RUN rm -rf /workspace/llama.cpp

EXPOSE 10000

CMD ["llama-server", "-hf", "unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_X", "--port", "10000", "--host", "0.0.0.0", "--ctx-size", "65536"]
