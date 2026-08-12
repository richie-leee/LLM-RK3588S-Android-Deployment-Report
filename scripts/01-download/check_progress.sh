#!/bin/bash
# 查看模型下载进度（干净输出）
cd "$(dirname "$0")/models" || exit 1
declare -A WANT=(
  [glm-edge-4b-chat.Q4_K_M.gguf]=2627489280
  [glm-edge-v-5b-Q4_K_M.gguf]=2627488800
  [mmproj-model-f16.gguf]=1028670432
)
total_have=0; total_want=0; alldone=1
for f in glm-edge-4b-chat.Q4_K_M.gguf glm-edge-v-5b-Q4_K_M.gguf mmproj-model-f16.gguf; do
  want=${WANT[$f]}; have=0
  [ -f "$f" ] && have=$(stat -c %s "$f")
  pct=$(( have * 100 / want ))
  bar=$(printf '%*s' $((pct/4)) '' | tr ' ' '#')
  printf "%-32s %5s%% [%-25s] %s\n" "$f" "$pct" "$bar" \
    "$(awk -v h=$have -v w=$want 'BEGIN{printf "%.2f/%.2f GB", h/1073741824, w/1073741824}')"
  total_have=$((total_have+have)); total_want=$((total_want+want))
  [ "$have" -ne "$want" ] && alldone=0
done
echo "-----------------------------------------------------------------------"
printf "总计 %d%%  %.2f / %.2f GB\n" $((total_have*100/total_want)) \
  "$(echo "scale=2; $total_have/1073741824" | bc)" "$(echo "scale=2; $total_want/1073741824" | bc)"
if [ "$alldone" -eq 1 ]; then echo ">>> 全部下载完成"; else
  running=$(ps -W 2>/dev/null | grep -c "[c]url")
  echo ">>> curl 进程数: $running"
fi
