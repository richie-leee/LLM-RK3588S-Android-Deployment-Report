# Offline Large Model Deployment Research Report

> **Executive Summary:** This report presents comprehensive on-device testing of multimodal large language models on the RK3588S hardware platform:
> The current Android edge-side domestic offline large models are divided into two major community ecosystems: **llama.cpp+GGUF open source** with abundant community resources, fast model adaptation, and good cross-chip compatibility; **Alibaba MNN** ecosystem relies on vendor-specific partnerships with proprietary model packages but privatized formats and fewer third-party resources. Built-in NPU has permission and format barriers that prevent usage, Mali GPU inference efficiency is lower than CPU in actual tests and provides no acceleration value;
> This investigation identifies three deployment forms: **①** GGUF+llama.cpp native CLI/server, **②** MNN inference engine with supporting APK, **③** MiniCPM packaged APK based on llama.cpp encapsulation;
> The investigation covers **8** vendors with a total of **31** domestic/international multimodal models, excluding solutions with parameters >7B, cloud APIs, or requiring Root permissions. Testing shows that only **MiniCPM Intelligence, Zhipu AI, DeepSeek** have models meeting operational standards. Most vendor models have issues including lack of public deployment packages, crashes, garbled output, missing configuration files, etc.;
> Among them, only **2** models meet product-ready standards. Based on comprehensive testing of latency, memory footprint, and multi-turn dialogue stability, the primary recommendations are Zhipu **GLM-Edge-V-2B (GGUF+llama.cpp route) and MiniCPM MiniCPM-1.2B packaged APK** as two solutions.

## I. Investigation Overview

### 1.1 Background

#### 1.1.1 Requirements

Plan to deploy edge-side multimodal large language models on learning tablets to enable AI interaction capabilities including image understanding, visual Q&A, and multi-turn dialogue.

#### 1.1.2 Current Pain Points

Previously attempted deployment of MiniCPM models (1B/1.2B)

The actual experience revealed the following reproducible issues: ① Visual reasoning response time too long: image understanding tasks exceed user-acceptable end-to-end time; ② Insufficient multi-turn dialogue stability: occasional output anomalies in consecutive follow-up scenarios; ③ Incomplete deployment pipeline: end-to-end process from model loading to inference output has interruptions;

**Preliminary Assessment**: Current experience bottlenecks mainly stem from issues with native deployment configuration and model selection bias, not the capability ceiling of edge-side multimodal models. This investigation will systematically verify the technical feasibility and product usability of multimodal models under unified hardware environment and testing standards.

#### 1.1.3 Hardware Constraints

This investigation completed all on-device testing on the RK3588S platform (8-core CPU, 12GB memory, Android 12). Core hardware conclusions are as follows:

| Computing Unit | Availability | Description |
| --- | --- | --- |
| CPU | ✅ Primary computing unit | ARM NEON optimization sufficient, measured inference speed meets edge-side interaction baseline |
| GPU (Mali-G610) | ❌ Measured speed significantly slower than CPU, not adopted | OpenCL measured inference performance lower than CPU, no acceleration benefit |
| NPU (RKNN, 6 TOPS) | ❌ Currently not deployment-ready | Hardware exists, but no mature adaptation for multimodal models, software pipeline not established |

**Platform Capability Boundaries:**

- RK3588S available memory approximately 8-10GB, measured 7B parameter model inference speed already significantly declined, therefore this investigation excludes models with parameters > 7B from testing scope

- All conclusions in this chapter are based on RK3588S platform measurements and do not generalize to other hardware platforms (Unisoc T760, etc.)

### 1.2 Investigation Objectives and Success Criteria

#### 1.2.1 Investigation Objectives

The objective of this investigation is to screen multimodal models that can run stably on RK3588S, clarify viable technical routes for inference engines plus model formats, identify bottlenecks in current deployment solutions, and output selection recommendations based on measured data.

#### 1.2.2 Success Criteria

| Criteria | Definition | Status |
| --- | --- | --- |
| Engineering Operational | Model can load inference, basic functions can be triggered, but reproducible defects exist such as multi-turn anomalies | ⚠️ Functionally deficient pass |
| Product Ready | Complete functionality, stable multi-turn dialogue, latency meets interaction requirements | ✅ Verification pass |

**P0 (Must Achieve):**

- Screen at least 1 domestic multimodal model meeting product-ready standards

- Clarify deployable technical route (inference engine + model format + deployment method)

- Provide clear selection recommendations based on measured data

**P1 (Expected Achievement):**

- Identify bottlenecks in existing MiniCPM deployment solution

- Find 2-3 alternative model solutions

- Complete multi-dimensional horizontal comparison

### 1.3 Investigation Methods and Evaluation Dimensions

#### 1.3.1 Investigation Methods

| Channel | Purpose |
| --- | --- |
| Vendor official documentation | Confirm model architecture, quantization schemes, deployment guides |
| Inference engine documentation | MNN / llama.cpp deployment documentation |
| Community information | GitHub Issues/Discussions, HuggingFace/ModelScope |
| On-device testing (core) | Actual deployment, inference testing, log analysis |

#### 1.3.2 Evaluation Dimensions

This investigation records model performance along the following four dimensions, with all observations presented uniformly in Chapter 4:

| Dimension | Examination Content |
| --- | --- |
| Image recognition function | Whether image recognition tasks complete normally |
| Multi-turn dialogue stability | Whether consecutive follow-ups have garbled text or confusion |
| Inference latency | End-to-end inference time consumption |
| Memory footprint | Peak memory during operation |

### 1.4 Investigation Scope

#### 1.4.1 Included Content

- **Models**: Mainstream domestic open-source multimodal large models

- **Technology stack**: GGUF + llama.cpp, MNN two edge-side inference technical routes (including corresponding model formats and inference engines)

- **Hardware platform**: RK3588S as primary testing platform

#### 1.4.2 Excluded Content

| Exclusion Item | Reason |
| --- | --- |
| International models (LLaVA, etc.) | Investigation focuses on domestic solutions |
| Text-only models | Requirements demand multimodal |
| Cloud API models | Requirements demand edge-side offline |
| Parameters > 7B | 7B already slow on RK3588S, larger models don't meet platform usability expectations |
| GPU acceleration solutions | No acceleration benefit in measurements |
| Solutions requiring Root permissions | Board lacks Root permissions |

## Core Conclusions

**Conclusion 1: Technical Routes**

Two viable technical routes exist for edge-side multimodal deployment: GGUF + llama.cpp and MNN. Both routes completed end-to-end verification on RK3588S and can support local inference of domestic multimodal models.

**Conclusion 2: Model Selection**

This investigation tested 8 vendors with 31 models, of which 5 reached engineering operational standards and 2 reached product-ready standards.

Models meeting product-ready standards: MiniCPM MiniCPM-V-4 (MNN), Zhipu GLM-Edge-V-2B (GGUF + llama.cpp). Both support image recognition and multi-turn dialogue with acceptable inference latency.

**Conclusion 3: Overall Assessment**

Edge-side multimodal models have achieved breakthrough from unusable to operational on domestic chips, but still have significant distance from stable product delivery. Most operational models have reproducible issues such as high latency and multi-turn dialogue anomalies. Product usability (runs well) maturity remains lower than technical feasibility (runs at all).

## II. Testing Environment and Baseline Methods

### 2.1 Testing Platform

#### 2.1.1 Primary Testing Platform: RK3588S

All on-device testing work completed on the following hardware platform:

| Item | Specification | Impact on Inference |
| --- | --- | --- |
| SoC | Rockchip RK3588S | — |
| CPU | 8-core (4×A76 @ 2.4GHz + 4×A55 @ 1.8GHz) | Primary computing unit, ARM NEON optimization sufficient |
| Memory | 12GB LPDDR4X | Available approximately 8-10GB, 7B already slow, >7B not included in testing |
| NPU | RKNN, 6 TOPS | Hardware exists, software pipeline not established, not adopted this time |
| GPU | Mali-G610 MP4 | OpenCL measured no acceleration benefit, not adopted this time |
| System | Android 12 | — |
| Connection method | USB debugging (ADB) | — |

#### 2.1.2 Hardware Capability Verification Summary

**CPU**: Measured inference speed 9-14 tok/s (text generation phase), can support edge-side interaction baseline.

**GPU (Mali-G610)**: Verified using llama.cpp OpenCL backend. Measured GPU inference speed (8.59 t/s) in image processing (pp32) scenario lower than CPU baseline (61.76 t/s); text generation (tg128) scenario GPU (6.63 t/s) also lower than CPU (13.49 t/s). Conclusion: Mali GPU provides no acceleration benefit on this platform, not adopted this time.

Note: llama.cpp OpenCL backend mainly optimized for Qualcomm Adreno GPU, execution efficiency low on ARM Mali. This conclusion only applies to this platform and does not generalize to other GPU models.

**NPU (RKNN)**: Hardware specification 6 TOPS INT8. Verified that no multimodal model adapted versions currently exist, and model formats (GGUF/MNN) incompatible with RKNN, software pipeline not established. Conclusion: NPU currently does not have conditions for edge-side multimodal model deployment, not adopted this time.

#### 2.1.3 Legacy Platform Reference: Unisoc UMS9620 (T760)

Some preliminary verification work completed on Unisoc T760 platform as legacy device reference:

| Item | Specification |
| --- | --- |
| CPU | 8-core (4×A76 @ 2.2GHz + 4×A55 @ 2.0GHz) |
| Memory | 8GB (actual available approximately 3.9GB) |
| NPU | Imagination AURA, 1GHz, 16 convolution blocks |
| GPU | Mali-G57 |
| System | Android 15 |

Unisoc platform also verified GPU (OpenCL) acceleration not viable (slower than CPU), NPU path (libunillmai.so / libimgdnn.so) due to ordinary App lacking permissions to call, also unusable. All subsequent model selection testing completed on RK3588S.
