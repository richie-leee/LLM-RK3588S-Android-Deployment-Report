# GLM-Edge 部署与测试脚本

在 ARM 安卓设备（RK3588S / Android 12）上通过 Termux + llama.cpp 部署 GLM-Edge 系列模型的完整脚本集，覆盖模型下载、推送、编译、测试到数据解析的全流程。

## 环境

| 项 | 值 |
| --- | --- |
| 硬件 | RK3588S，8 核（4×A76 @2.4GHz + 4×A55 @1.8GHz），12GB LPDDR4X |
| 系统 | Android 12 |
| 推理引擎 | llama.cpp，[piDack/llama.cpp](https://github.com/piDack/llama.cpp) `support_glm_edge_model` 分支 |
| 计算后端 | 仅 CPU（ARM NEON）。GPU/NPU 实测不可用，见主报告第 3.3 节 |
| 板端环境 | Termux（F-Droid 版，勿用 Play 商店版） |

## 执行顺序

```
01-download   (PC)     下载 GGUF 模型
02-transfer   (PC)     adb push 到板子
03-termux-build (板端)  编译 llama.cpp
04-test       (板端)    功能与性能测试
05-analysis   (PC)     解析日志、导出数据
```

---

## 01-download — 模型下载（PC）

从 hf-mirror.com 拉取 GGUF 模型。支持断点续传，重复执行会跳过已完整的文件。

| 脚本 | 说明 |
| --- | --- |
| `download_curl_seq.sh` | **推荐**。curl 单线程顺序下载，按字节数校验完整性 |
| `download_models.sh` | 早期版本，并行下载 |
| `resume_download.sh` | 续传中断的下载 |
| `check_progress.sh` | 实时查看下载进度 |
| `verify_and_reorganize.sh` | 校验字节数并整理目录（V-5B 归入 `v5b/`） |

```bash
bash scripts/01-download/download_curl_seq.sh
bash scripts/01-download/verify_and_reorganize.sh   # 校验不通过不要继续
```

覆盖的模型：

| 模型 | 文件 | 大小 |
| --- | --- | --- |
| GLM-Edge-1.5B-Chat | `glm-edge-1.5b-chat.Q4_K_M.gguf` | 935 MB |
| GLM-Edge-V-2B | `v2b/ggml-model-Q4_K_M.gguf` + `v2b/mmproj-model-f16.gguf` | 935 MB + 890 MB |
| GLM-Edge-4B-Chat | `glm-edge-4b-chat.Q4_K_M.gguf` | 2.5 GB |
| GLM-Edge-V-5B | `v5b/ggml-model-Q4_K_M.gguf` + `v5b/mmproj-model-f16.gguf` | 2.5 GB + 1 GB |

---

## 02-transfer — 推送到板子（PC）

```bash
adb devices    # 先确认设备已连接
bash scripts/02-transfer/transfer_and_test.sh
```

在板子上建立 `/sdcard/models/{v2b,v5b}/` 并推送全部模型（约 6GB，5-10 分钟），同时推送板端脚本。

---

## 03-termux-build — 编译 llama.cpp（板端手动执行）

adb 无法代为执行 Termux 内的命令，需在板子的 Termux 应用里手动运行。

```bash
# 若默认源速度过慢（实测 16 kB/s），先换清华镜像
bash /sdcard/termux_fix_mirror.sh

# 编译（15-25 分钟）
bash /sdcard/termux_setup_glm_edge_final.sh
```

`termux_setup_glm_edge_final.sh` 依次完成：安装 `git clang cmake python` → 克隆 piDack 分支 → `cmake --build build -j8` → `cp` 模型至 `~/models/`。

> 用 `cp` 而非 `mv`：`/sdcard` 与 Termux 家目录不同文件系统，`mv` 会失败。

**编译后必须确认多模态二进制的实际名称**，不同分支产物名不同：

```bash
ls ~/llama.cpp/build/bin/
```

- `llama-cli` — 纯文本，必定存在
- `llama-llava-cli` **或** `llama-mtmd-cli` — 多模态，记下是哪个，后续测试脚本需对应

---

## 04-test — 测试（板端）

| 脚本 | 用途 |
| --- | --- |
| `test_v2b.sh` | V-2B 单图识别，最小验证 |
| `test_v2b_multi.sh` | V-2B 多图连续识别（3 张） |
| `test_text_correct.sh` | 纯文本对话（语法讲解 / 代码解释 / 常识问答） |
| `auto_qa.sh` | 自动问答 3 组，无需交互 |
| `chat_interactive.sh` | 交互式多轮对话 |
| `compare_models_fixed.sh` | V-2B 与 1.5B-Chat 同题对比 |
| `bench.sh` | `llama-bench` 跑 prefill/decode 吞吐，结果写入 `/sdcard/bench_result.txt` |
| `start_web_server.sh` | 起 `llama-server`，浏览器访问 `http://localhost:8080` 可拖图提问 |

### 测试图片准备

多数脚本读取 `~/test.jpg`，`test_v2b_multi.sh` 读取 `/sdcard/testimg/` 下的全部图片。自备图片推送即可：

```bash
# 单图
adb push <本地图片> /sdcard/test.jpg
# Termux 内：cp /sdcard/test.jpg ~/test.jpg

# 多图
adb shell mkdir -p /sdcard/testimg
adb push <本地图片目录>/. /sdcard/testimg/
```

建议覆盖三类：自然场景（通用理解）、含文字的文档图（验 OCR）、多对象复杂场景（验细粒度识别）。本次调研另用一张合成图固定校验 OCR——纯色背景 + 几何图形 + 一行已知文本，便于逐字比对识别结果。

多模态调用形式：

```bash
cd ~/llama.cpp
./build/bin/llama-llava-cli \
  -m ~/models/v2b/ggml-model-Q4_K_M.gguf \
  --mmproj ~/models/v2b/mmproj-model-f16.gguf \
  --image ~/test.jpg \
  -p "<|user|>
描述这张图片<|assistant|>
" \
  -n 256 -t 8 -c 2048
```

要点：

- GLM-Edge 的 prompt 模板是 `<|user|>` / `<|assistant|>`，换行不能省
- `-t 8` 对应 8 核；`-c 2048` 上下文长度
- 纯文本测试也需传 `--image`（`llama-llava-cli` 强制要求），脚本里用 1×1 白图占位以避开图像编码耗时
- 首 token 延迟 3-6 秒属正常，别当成卡死

同时开另一个 Termux 会话跑 `htop` 记录 RES 峰值与 CPU 占用。

---

## 05-analysis — 数据解析（PC）

| 脚本 | 用途 |
| --- | --- |
| `dump_latency.py` | 从 logcat 时间戳提取图像编码 / prefill / decode 各阶段耗时 |
| `dump_qa2.py` | 导出问答对，核对输出质量 |
| `analyze_quality.py` | 汇总识别准确性 |
| `read_chat_db.py` | 读取 APK 侧对话数据库 |
| `stat2.py` | 统计汇总 |

内存采集：

```bash
adb shell dumpsys meminfo <包名> | grep "TOTAL PSS"
```

---

## 实测结果

GLM-Edge-V-2B 在本平台的数据（4 次取均值）：

| 指标 | 值 |
| --- | --- |
| 图像 embedding | 578 tokens（恒定） |
| 图像编码 | 27.74 s |
| prefill | 26.94 t/s |
| decode | 9.13 t/s |
| 模型加载 | 52.25 s |
| KV cache | 224 MiB（4096 ctx，28 层） |
| flash_attn | 关闭 |

完整数据与其他 5 款模型的横向对比见 [主报告](../README.md)。

---

## 已知问题

**`unknown option --mmproj`** — 该分支多模态入口参数不同，先查：

```bash
./build/bin/llama-llava-cli --help | grep -i image
```

**`n_ctx_per_seq (4096) > n_ctx_train (2048)`** — GLM-Edge-V-2B 训练上下文为 2048，超出会有此告警。实测输出正常，但长上下文场景需注意。

**Termux 装包极慢** — 默认源实测仅 16 kB/s，跑 `termux_fix_mirror.sh` 换清华源。

**编译 OOM** — 把 `-j8` 降到 `-j4`。
