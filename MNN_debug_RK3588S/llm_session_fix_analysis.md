# LLM Session 多轮多模态修复分析

## 问题根源

### 原始代码缺陷（llm_session.cpp:295-318）

```cpp
// ❌ BUG #1: 拼接全部历史
std::string full_prompt_text;
for (auto & it : history_) {
    full_prompt_text += it.second;  // 包含所有旧的<img>标签
}

// ❌ BUG #2: 从全历史提取图片
auto multimodal_result = processMultimodalPrompt(full_prompt_text);

if (multimodal_result.has_multimodal) {
    // ❌ BUG #3: 只传multimodal_prompt，丢失历史上下文
    llm_->response(multimodal_result.multimodal_prompt, ...);
} else {
    llm_->response(history_, ...);  // text分支保留了历史
}
```

### 导致的症状

**Round 1（首轮带图）：**
- history_ = [system, user+img1]
- full_prompt_text包含1个<img>标签
- 模型收到：system + user + img1 → ✅ 正常回答

**Round 2（第二轮带图）：**
- history_ = [system, user+img1, assistant, user+img2]
- full_prompt_text包含2个<img>标签（img1 + img2）
- 模型收到：img1 + img2 + 没有历史文本 → ❌ "好的好的"（回避）

**Round 3（纯文本"你是谁"）：**
- history_ = [system, user+img1, assistant, user+img2, assistant, user]
- 走text分支，history_正确传递
- 但是history_里还有`<img>path</img>`字符串（没清理）
- omni.cpp提取所有<img>标签 → 加载img1+img2
- system prompt被埋在中间，角色混乱 → ❌ "我是我是我是"（重复）

**Round 4（第三轮带图）：**
- history_包含3个<img>标签
- 模型收到3张图 + 极度污染的prompt → ❌ "您好！"（崩溃）

## 修复方案

### 核心改动（llm_session.cpp:293-351）

```cpp
// ✅ FIX #1: 只从当前用户消息提取multimodal
const std::string& current_user_msg = history_.back().second;
auto multimodal_result = processMultimodalPrompt(current_user_msg);

if (multimodal_result.has_multimodal) {
    // ✅ FIX #2: 构建完整历史，清理旧multimodal标签
    std::vector<PromptItem> history_for_multimodal;
    std::regex multimodal_tag_regex("<(img|video|audio)>.*?</\\1>");
    
    // 保留历史文本，但剥离旧的multimodal标签
    for (size_t i = 0; i < history_.size() - 1; ++i) {
        std::string cleaned_content = std::regex_replace(
            history_[i].second, multimodal_tag_regex, "");
        history_for_multimodal.emplace_back(history_[i].first, cleaned_content);
    }
    
    // 当前消息保留multimodal内容
    history_for_multimodal.emplace_back("user", 
        multimodal_result.multimodal_prompt.prompt_template);
    
    // ✅ FIX #3: 应用完整chat template（保留角色标记）
    std::string formatted_prompt = llm_->apply_chat_template(history_for_multimodal);
    multimodal_result.multimodal_prompt.prompt_template = formatted_prompt;
    
    // ✅ FIX #4: 手动tokenize，避免llm.cpp:990行的重复模板应用
    std::vector<int> input_ids = llm_->tokenizer_encode(
        multimodal_result.multimodal_prompt);
    
    // 直接传token IDs，绕过模板处理
    llm_->response(input_ids, &output_ostream, "<eop>", 0);
}
```

### 修复后的行为

**Round 1（首轮带图）：**
- 提取：current_user_msg → img1
- 历史：[system(清理), user+img1(保留)]
- 模型收到：完整格式化的prompt + img1 → ✅ 正常

**Round 2（第二轮带图）：**
- 提取：current_user_msg → img2（不包含img1）
- 历史：[system(清理), user+文本(清理), assistant, user+img2(保留)]
- 模型收到：完整上下文 + 只有img2 → ✅ 正常

**Round 3（纯文本）：**
- 走text分支
- history_里还有`<img>path</img>`？ → **仍会被omni提取**
- ⚠️ **text分支也需要清理历史中的multimodal标签**

**Round 4（第三轮带图）：**
- 提取：current_user_msg → img3（不包含img1/img2）
- 历史：完整清理后的对话 + img3 → ✅ 正常

## 完整修复方案

### 核心修改（llm_session.cpp:293-361）

**修改点1：永久清理历史中的multimodal标签（第293-301行）**
```cpp
// CRITICAL FIX #1: Clean multimodal tags from all previous turns in history_
// to prevent re-loading old images in subsequent rounds (both multimodal and text branches).
// Keep ONLY the current user message intact for processing.
if (history_.size() > 1) {
    std::regex multimodal_tag_regex("<(img|video|audio)>.*?</\\1>");
    for (size_t i = 0; i < history_.size() - 1; ++i) {
        history_[i].second = std::regex_replace(history_[i].second, multimodal_tag_regex, "");
    }
}
```

**修改点2：只从当前消息提取multimodal（第303-307行）**
```cpp
// CRITICAL FIX #2: Only process multimodal content from the CURRENT user message,
// not from accumulated history. This prevents old images from being re-loaded
// and mixed with new ones.
const std::string& current_user_msg = history_.back().second;
auto multimodal_result = processMultimodalPrompt(current_user_msg);
```

**修改点3：构建完整历史+当前multimodal（第323-345行）**
```cpp
// Build complete conversation history with multimodal content
std::vector<PromptItem> history_for_multimodal;
std::regex multimodal_tag_regex("<(img|video|audio)>.*?</\\1>");

// Add all previous messages (already cleaned by FIX #1)
for (size_t i = 0; i < history_.size() - 1; ++i) {
    std::string cleaned_content = std::regex_replace(history_[i].second, multimodal_tag_regex, "");
    history_for_multimodal.emplace_back(history_[i].first, cleaned_content);
}

// Add current user message with multimodal content
history_for_multimodal.emplace_back("user", multimodal_result.multimodal_prompt.prompt_template);

// Apply chat template to the complete history
std::string formatted_prompt = llm_->apply_chat_template(history_for_multimodal);
multimodal_result.multimodal_prompt.prompt_template = formatted_prompt;
```

**修改点4：手动tokenize避免重复模板应用（第350-357行）**
```cpp
// Manually tokenize the multimodal prompt to avoid double template application
// (llm_->response(MultimodalPrompt) would call apply_chat_template again)
std::vector<int> input_ids = llm_->tokenizer_encode(multimodal_result.multimodal_prompt);

// Call response with token IDs directly, bypassing template application
llm_->response(input_ids, &output_ostream, "<eop>", 0);
```

### 关键设计决策

**Q: 为什么在第296-301行永久修改history_？**

A: 一旦multimodal内容被处理，技术标签`<img>path</img>`就失去作用。保留它只会在后续轮次造成污染：
- Text分支会通过omni.cpp的tokenizer_encode自动提取并重新加载图片
- Multimodal分支如果不清理也会累积
- 历史对话的文本内容完整保留，只是去掉了技术标记

**Q: 第332-335行的清理是否冗余？**

A: 技术上是冗余的（第296-301行已清理），但保留作为防御性编程，确保history_for_multimodal绝对干净。

**Q: text分支（第360行）是否安全？**

A: 安全。因为：
1. 第296-301行已清理history_中的所有旧multimodal标签
2. llm_->response(history_)会调用apply_chat_template然后tokenizer_encode
3. 即使是Omni模型，tokenizer_encode也找不到`<img>`标签可提取

### 遗留问题

### 2. processor.cpp的设计缺陷

**问题**：HandleImageTags生成`image_0`作为key，但不替换prompt中的路径

**代码对比**：
```cpp
// ❌ HandleImageTags (line 116-127)
auto image_var = LoadImageFromPath(image_path);
if (image_var.get() != nullptr) {
    std::string image_key = "image_" + std::to_string(state.image_index);
    result.multimodal_prompt.images[image_key] = image_part;
    // 缺少：state.final_prompt替换操作
}

// ✅ HandleVideoTags (line 178-182)
state.final_prompt = std::regex_replace(
    state.final_prompt,
    std::regex("<video>" + escaped_path + "</video>"),
    video_result.prompt_template  // 包含image_0, image_1等
);
```

**影响**：omni.cpp的processImageContent找不到key，走fallback重新加载（性能浪费）

**解决方案**：修改HandleImageTags，成功加载后替换路径为key：

```cpp
if (image_var.get() != nullptr) {
    std::string image_key = "image_" + std::to_string(state.image_index);
    // ...
    
    // 替换路径为key
    const std::string escaped_path = EscapeForRegex(image_path);
    state.final_prompt = std::regex_replace(
        state.final_prompt,
        std::regex("<img>" + escaped_path + "</img>"),
        "<img>" + image_key + "</img>"
    );
}
```

### 3. LoadImageFromPath失败

**问题**：processor.cpp:116行LoadImageFromPath返回nullptr

**可能原因**：
1. CMakeLists缺少`-DMNN_IMGCODECS`宏定义
2. MNN::CV::imread实现有问题

**验证**：检查processor.cpp编译时是否定义了MNN_IMGCODECS

**影响**：processor预加载失效，但omni fallback能救场，不影响功能

## 测试验证

### 预期行为

**场景1：图+问 → 图+问**
- Round 1: img1 → 正确识别img1
- Round 2: img2 → 正确识别img2（不受img1干扰）

**场景2：图+问 → 文本 → 图+问**
- Round 1: img1 → 正确
- Round 2: "你是谁" → 正确身份（不加载img1）
- Round 3: img2 → 正确识别img2

**场景3：多轮上下文保持**
- Round 1: img1 + "图里有什么" → "一只猫"
- Round 2: "它是什么颜色" → "橙色"（记住前面说的猫）
- Round 3: img2 + "这个呢" → 正确切换到img2

### 需要抓取的日志

```
submitNative history count ...
Detected multimodal content in current message, using multimodal API with ... images
Multimodal prompt with complete history, final template length: ...
Tokenized multimodal prompt into ... tokens
```

对比修复前后：
- images数量：修复前累加，修复后固定为1
- template length：修复后应该增长（包含历史）
- tokens数量：修复后应该更多（包含历史context）
