FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

ENV HF_HOME=/workspace/.cache/huggingface \
    HF_HUB_CACHE=/workspace/.cache/huggingface/hub

RUN mkdir -p /workspace/.cache/huggingface/hub

WORKDIR /workspace

RUN git clone https://github.com/ggml-org/llama.cpp.git
WORKDIR /workspace/llama.cpp

RUN cmake -B build -DGGML_CUDA=ON && \
    cmake --build build -j"$(nproc)" && \
    cp build/bin/llama-* /usr/local/bin/

WORKDIR /workspace
RUN rm -rf /workspace/llama.cpp

EXPOSE 10000

CMD ["llama-server", "-hf", "unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_X", "--port", "10000", "--host", "0.0.0.0", "--ctx-size", "65536"]