#!/data/data/com.termux/files/usr/bin/bash
cd ~/llama.cpp
OUT=/sdcard/bench_result.txt
: > $OUT
for m in ~/models/v2b/ggml-model-Q4_K_M.gguf ~/models/glm-edge-1.5b-chat.Q4_K_M.gguf; do
  echo "=== $m ===" >> $OUT
  ./build/bin/llama-bench -m "$m" -p 512 -n 128 -t 8 -r 2 >> $OUT 2>&1
done
echo "BENCH_DONE" >> $OUT
cat $OUT...[truncated 24 chars]