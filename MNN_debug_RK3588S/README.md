# MNN 多轮多模态对话修复补丁

针对阿里 MNN Android LLM Chat 应用在 RK3588S 平台多轮多模态对话场景下的 bug 修复。

## 问题描述

**原始行为**（MNN 官方版本）：
1. **历史图片重复加载**：多轮对话时，之前轮次的图片会被反复加载，导致视觉编码时延累积（第 2 轮 = 2 张图，第 3 轮 = 3 张图）
2. **上下文丢失**：纯文本模式下，只传当前问题，不包含历史对话，模型无法记住之前的内容
3. **模板重复应用**：每轮都用 `applyTemplate` 包裹完整历史，导致系统提示词重复

**实测影响**（RK3588S 平台）：
- 第 1 轮图片识别：27 秒（正常）
- 第 2 轮纯文本追问：仍需 27 秒（错误，应 <1 秒）
- 第 3 轮换图：54 秒（加载 2 张图，错误）

## 修复方案

修改文件：`apps/Android/MnnLlmChat/app/src/main/cpp/llm_session.cpp`

### 四个关键修复点

#### Fix #1: 清理历史中的多模态标签
```cpp
// 从历史消息中移除所有 <img>/<video>/<audio> 标签
std::regex multimodal_tag_regex("<(img|video|audio)>.*?</\\1>");
for (size_t i = 0; i < history_.size() - 1; ++i) {
    history_[i].second = std::regex_replace(history_[i].second, multimodal_tag_regex, "");
}
```

#### Fix #2: 只从当前消息提取图片
```cpp
// 只处理最后一条用户消息的图片，不累积历史
const std::string& current_user_msg = history_.back().second;
auto multimodal_result = processMultimodalPrompt(current_user_msg);
```

#### Fix #3: 多模态分支保留完整历史
```cpp
// 构建包含历史的 multimodal prompt
multimodal_prompt.prompt_template = Llm::Prompt::applyTemplate(llm_->model_type_, history_, &output_ostream, "<eop>", 0);
// 不再只传图片路径，而是完整对话上下文
```

#### Fix #4: 纯文本分支保留完整历史
```cpp
// 构建包含历史的纯文本 prompt
std::string text_only_prompt = Llm::Prompt::applyTemplate(llm_->model_type_, history_, &output_ostream, "<eop>", 0);
// 手动 tokenize 避免重复应用模板
auto text_tokens = llm_->tokenizer(text_only_prompt.c_str());
llm_->load_tokens_directly(text_tokens, &output_ostream);
```

## 修复效果

| 场景 | 修复前 | 修复后 |
|------|--------|--------|
| 第 1 轮：图 1 + "描述" | 27s | 27s |
| 第 2 轮：纯文本追问 | 27s（重新加载图 1） | <1s（纯文本推理） |
| 第 3 轮：图 2 + "这个呢" | 54s（加载图 1+2） | 27s（仅加载图 2） |
| 上下文保持 | ❌ 不记得之前说的 | ✅ 正确引用历史 |

## 如何应用补丁

### 方法 1：使用 patch 命令（推荐）

```bash
# 克隆官方 MNN 仓库
git clone https://github.com/alibaba/MNN.git
cd MNN

# 应用补丁
patch -p1 < /path/to/llm_session.patch

# 验证修改
git diff apps/Android/MnnLlmChat/app/src/main/cpp/llm_session.cpp
```

### 方法 2：手动修改

打开 `apps/Android/MnnLlmChat/app/src/main/cpp/llm_session.cpp`，参照 patch 文件手动修改第 293-361 行。

### 方法 3：直接替换修改后的文件

（本仓库提供修改后的完整文件 `llm_session_fixed.cpp`，复制到对应位置并重命名）

## 编译

修改后需重新编译 Android APK：

```bash
cd MNN/project/android
# 按 MNN 官方文档执行 gradle 构建
./gradlew assembleRelease
```

生成的 APK 在 `app/build/outputs/apk/release/`。

## 测试验证

多轮对话测试用例：

```
轮 1: [上传猫图] "图里有什么"
     → 应答："一只橙色的猫"（27s，正常）

轮 2: "它在做什么"
     → 应答："躺着"（<1s，不应重新加载图片）

轮 3: [上传狗图] "这个呢"
     → 应答："一只棕色的狗"（27s，只加载新图）

轮 4: "对比前两张图"
     → 应答："第一张是猫躺着，第二张是狗..."（引用历史）
```

## 技术细节

### 根本原因

MNN 原始实现把 `processMultimodalPrompt(full_prompt_text)` 应用于完整历史字符串拼接结果，导致：
- 所有历史 `<img>` 标签都被提取并加载
- embedImage 函数每次都处理全部历史图片
- KV cache 虽然能复用文本 token，但视觉 embedding 无法缓存

### 关键设计

1. **历史清理在最前**：修改 `history_` 后立即清理，保证后续分支（多模态/纯文本）都看到干净的历史
2. **只处理当前轮**：`processMultimodalPrompt` 只接收 `history_.back()`
3. **模板应用后置**：清理完历史后再调用 `applyTemplate`，避免标签残留
4. **分支统一**：多模态和纯文本都用完整 `history_` 构建 prompt，保证上下文一致

## 法律声明

本补丁基于 [阿里 MNN](https://github.com/alibaba/MNN) 项目（Apache License 2.0）。

原始版权归阿里巴巴集团所有。本修改遵循 Apache 2.0 许可证，在保留原始版权声明的前提下，对源代码进行了修改。

修改内容标注为 `CRITICAL FIX #1-4`，详见 patch 文件。

## 参考

- MNN 官方仓库：https://github.com/alibaba/MNN
- 相关 issue：MNN 官方暂无此问题的公开讨论
- 测试平台：RK3588S (8核，12GB，Android 12)
- 测试模型：MiniCPM-V-4 (MNN)、Qwen3-VL-2B-Thinking (MNN)

## 贡献者

- 问题定位与修复：基于 RK3588S 平台实测发现
- 测试环境：详见主仓库报告 [README.md](../README.md)
