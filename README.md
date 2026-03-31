# runpod-llama-server

`llama.cpp` の `llama-server` を起動するためのシンプルな Runpod 向け Docker イメージです。

## 概要

- ベースイメージ: `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`
- サーバー: `llama-server`
- 公開ポート: `10000`
- Hugging Face キャッシュ: `/workspace/.cache/huggingface`

コンテナ起動時に `llama-server` が直接起動します。

## デフォルトの起動コマンド

デフォルトでは `unsloth/Qwen3.5-0.8B-GGUF` が起動します。

`llama-server -hf unsloth/Qwen3.5-0.8B-GGUF:Q4_K_M --host 0.0.0.0 --port 10000 --ctx-size 65536 --n-gpu-layers 999 --threads 16 --threads-batch 16 --parallel 1`
## モデルやオプションの変更

デフォルトの `CMD` を上書きすることで、モデル名や各種オプションを変更できます。

### 例: `HauhauCS/Qwen3.5-35B-A3B-Uncensored-HauhauCS-Aggressive` を使う場合

`llama-server -hf HauhauCS/Qwen3.5-35B-A3B-Uncensored-HauhauCS-Aggressive:Q4_K_M --host 0.0.0.0 --port 10000 --ctx-size 65536 --n-gpu-layers 999 --threads 16 --threads-batch 16 --parallel 1`

補足
ビルド時のみ CUDA stub を使用しています。
実行時は本物の NVIDIA ドライバを使う前提です。
モデルファイルは初回起動時に取得され、Hugging Face キャッシュは `/workspace/.cache/huggingface` に保存されます。
