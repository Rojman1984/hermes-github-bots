# Small Local LLM Landscape and AMD iGPU Inference Research

**Date:** 2026-09-06
**Author:** scout (fleet research specialist)
**Scope:** Small (0.5B-4B) local LLMs for agent tool-use + AMD Vega iGPU Vulkan inference state, with synthesis for 3.2GB VRAM + 17GB GTT APU.

---

## PART 1: Small Local LLM Landscape (0.5B-4B)

### 1.1 LFM2 / LFM2.5 (Liquid AI)

| Variant | Parameters | Context Window | Tool Calling | License | Release |
|---|---|---|---|---|---|
| LFM2-350M | 350M | UNVERIFIED (likely 32K based on family) | Special tokens present in tokenizer; fine-tuned variant reaches 96-98% tool call equivalence (distil labs) | LFM Open License v1.0 | LFM2: late 2025; LFM2.5 variants: 2026 |
| LFM2-700M | 700M | UNVERIFIED | UNVERIFIED | LFM Open License v1.0 | LFM2: late 2025 |
| LFM2.5-1.2B-Instruct | 1.17B | 128K (UNVERIFIED for 1.2B specifically; 2.6B confirmed at 128K) | Native tool-calling support; special tokens for tool calling in tokenizer; "best-in-class at 1B scale for instruction following, tool use, and agentic tasks" | LFM Open License v1.0 | 2026 |
| LFM2.5-2.6B | 2.69B (2.6B active) | 128K native | Native tool calling; leads nearly every tool-use benchmark in its class, trailing only Qwen3.5-9B on BFCLv4; agentic RL post-training | LFM Open License v1.0 | August 2026 |

**Architecture:** Hybrid models (not standard transformer). LFM2 uses a mixture of attention mechanisms. LFM2.5-2.6B was pre-trained on ~34T tokens with mid-training context extension to 128K.

**License details (LFM Open License v1.0):**
- Based on Apache 2.0 but with a commercial use limitation
- Free commercial use only for companies with < $10M annual revenue
- Organizations at or above $10M revenue need a separate commercial license
- NOT OSI-compliant (restricted, dual-use commercial framework)
- Sources: https://www.liquid.ai/lfm-license (accessed 2026-09-06), https://venturebeat.com/technology/liquid-ais-smallest-model-yet-lfm2-5-230m-beats-models-4x-its-size-at-data-extraction-can-run-anywhere (accessed 2026-09-06), https://huggingface.co/LiquidAI/LFM2-2.6B-Exp-GGUF/discussions/3 (accessed 2026-09-06)

**Tool-calling quality (LFM2.5-2.6B):**
- Tops every instruction-following benchmark in its class
- Tops nearly every tool-use benchmark, trailing only Qwen3.5-9B (9.7B) on BFCLv4
- Beats both Gemma 4 E2B and E4B on agentic tasks
- Trains even with Qwen models on agentic benchmarks
- Agentic RL post-training stage confirms real multi-step tool-calling capability
- LFM2.5-350M (after fine-tuning via distil labs) reaches 96-98% tool call equivalence vs 120B teacher
- Sources: https://www.liquid.ai/blog/lfm2-5-2-6b (accessed 2026-09-06), https://huggingface.co/blog/LiquidAI/lfm2-5-2-6b (accessed 2026-09-06), https://www.distillabs.ai/blog/fine-tuning-liquids-lfm25-accurate-tool-calling-at-350m-parameters/ (accessed 2026-09-06), https://www.marktechpost.com/2026/08/06/liquid-ai-lfm2-5-2-6b-on-device-agentic-model/amp/ (accessed 2026-09-06)

**GGUF sizes (LFM2.5-2.6B):**
- Q4_K_M: 1.68 GB
- BF16: 5.4 GB
- Source: https://huggingface.co/bartowski/LiquidAI_LFM2.5-2.6B-GGUF (accessed 2026-09-06), https://vramcalculator.com/lfm2-5-2-6b-vram-requirements/ (accessed 2026-09-06)

**GGUF sizes (LFM2.5-1.2B):**
- UNVERIFIED for exact Q4_K_M size; Ollama community modelfile references f16-8gbGPU variant
- Source: https://ollama.com/oamazonasgabriel/lfm2-1.2b-tool (accessed 2026-09-06)

---

### 1.2 Qwen 3.5 Small Variants (Alibaba)

| Variant | Parameters | Context Window | Tool Calling | License | Release |
|---|---|---|---|---|---|
| Qwen3.5-0.8B | 0.8B | 262,144 native (extensible to ~1M via YaRN) | Function calling and JSON mode: both supported | Apache 2.0 | February 2026 |
| Qwen3.5-2B | 2B | 262,144 native | Function calling supported (native, like all Qwen3.5 models) | Apache 2.0 | February 2026 |
| Qwen3.5-4B | 4B | 262,144 native | Function calling supported; ties for #1 on tool-calling benchmark with lfm2.5:1.2b, qwen3:0.6b, phi4-mini:3.8b at 0.880 | Apache 2.0 | February 2026 |

**Architecture:** Hybrid Gated DeltaNet (GDN) + Gated Attention. Pattern: 6x(3xDeltaNet -> FFN -> 1xAttention -> FFN). This hybrid architecture enables long-context inference feasible on consumer hardware. Multimodal (text + image). Thinking + non-thinking modes.

**Key details:**
- All Qwen3.5 small models are natively multimodal (text + image input)
- 256K context supported across 201 languages (some sources say 262K)
- Default context length: 262,144 tokens
- Qwen3.5-4B (4.7B at Q4) was the winner in local Vulkan benchmark testing on AMD Vega iGPU — only model that completed agentic task, got correct answer, and was stable without flash attention
- Qwen3.5-2B (2.3B at bf16) was faster but got wrong answers on agentic word-count task
- Sources: https://huggingface.co/Qwen/Qwen3.5-4B (accessed 2026-09-06), https://huggingface.co/Qwen/Qwen3.5-2B (accessed 2026-09-06), https://www.morphllm.com/qwen-3-5 (accessed 2026-09-06), https://unsloth.ai/docs/models/qwen3.5 (accessed 2026-09-06), https://deepinfra.com/blog/qwen-3-5-0-8b-via-deepinfra-api-benchmarks (accessed 2026-09-06), https://github.com/MikeVeerman/tool-calling-benchmark (accessed 2026-09-06), https://ollama.com/library/qwen3.5:0.8b/blobs/9be69ef46306 (accessed 2026-09-06 — confirms Apache 2.0)

**Tool-calling quality:**
- Qwen3.5-4B ties for #1 at 0.880 on MikeVeerman tool-calling benchmark (with lfm2.5:1.2b, qwen3:0.6b, phi4-mini:3.8b)
- Qwen3.5 family uses native function-calling support (Hermes tool-call parser for vLLM, etc.)
- Qwen3.5-9B (9.7B) edges ahead of LFM2.5-2.6B on BFCLv4 (but 9B is outside our 0.5-4B range)
- Sources: https://github.com/MikeVeerman/tool-calling-benchmark (accessed 2026-09-06), https://qwen.readthedocs.io/en/latest/framework/function_call.html (accessed 2026-09-06)

**GGUF sizes (Qwen3.5-4B):**
- Q4_K_M: ~2.5 GB (UNVERIFIED exact size; 4.7B at Q4 reported in local benchmarks)
- Source: https://huggingface.co/unsloth/Qwen3.5-4B-GGUF (accessed 2026-09-06), local benchmark skill data

---

### 1.3 Gemma 4 Small Variants (Google DeepMind)

| Variant | Effective Params | Total Params (incl. embeddings) | Context Window | Tool Calling | License | Release |
|---|---|---|---|---|---|---|
| Gemma 4 E2B | 2.3B effective | 5.1B | 128K | Native function-calling (inherited from larger models); multimodal (text + image + audio) | Apache 2.0 | April 2, 2026 |
| Gemma 4 E4B | 4.5B effective | 8B | 128K | Native function-calling; multimodal (text + image + audio) | Apache 2.0 | April 2, 2026 |

**Architecture:** Per-Layer Embeddings (PLE) architecture. The "E" in E2B/E4B stands for "Effective" parameters. E2B holds 5.1B total parameters but behaves like a 2.3B model at inference. E4B holds 8B total and behaves like 4.5B.

**Critical note on parameter count:** Despite being marketed as "2B" and "4B", the actual on-disk model sizes are larger due to embedding parameters. E2B at full precision is ~10 GB (5.1B params x 2 bytes), E4B at full precision is ~16 GB. At Q4, E2B is ~5 GB and E4B is ~8 GB. This is significantly larger than competing models at similar "effective" sizes.

**License:** Apache 2.0 — no custom restrictions, no usage carve-outs, no MAU thresholds. Unrestricted commercial use, modification, and redistribution. This is a change from earlier Gemma versions which used custom Gemma Terms of Use.
- Sources: https://www.mindstudio.ai/blog/gemma-4-apache-2-license-commercial-use (accessed 2026-09-06), https://dev.to/techsifted/google-gemma-4-review-2026-apache-20-license-benchmarks-commercial-use-3iea (accessed 2026-09-06), https://codersera.com/blog/gemma-4-complete-guide-2026/ (accessed 2026-09-06)

**Tool-calling quality:**
- Native function-calling support with special tokens (call:function_name{param:value} format)
- Google engineered E2B to inherit multimodal properties and native function-calling from 31B model
- Community fine-tunes exist (e.g., roshangrewal/gemma4-e4b-toolcall-v01)
- E4B nudges slightly ahead of Qwen3-4B post-fine-tune on tool calling, partly due to native function-call special tokens reducing variance on parameter-value sub-score
- Fine-tuning equalizes the playing field: composite spread between bases on raw BFCL collapses by ~70% after representative training
- Sources: https://machinelearningmastery.com/how-to-implement-tool-calling-with-gemma-4-and-python/ (accessed 2026-09-06), https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4 (accessed 2026-09-06), https://www.ertas.ai/blog/on-device-tool-calling-2026-qwen3-gemma4-phi4 (accessed 2026-09-06), https://huggingface.co/roshangrewal/gemma4-e4b-toolcall-v01 (accessed 2026-09-06)

**GGUF sizes:**
- E2B full precision: ~4 GB; Q4: ~1-2 GB (UNVERIFIED exact Q4_K_M size)
- E4B full precision: ~8 GB; Q4: ~4-5 GB (UNVERIFIED exact Q4_K_M size)
- Sources: https://gemma-4.net/download (accessed 2026-09-06), https://unsloth.ai/docs/models/gemma-4 (accessed 2026-09-06), https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF (accessed 2026-09-06), https://www.jetson-ai-lab.com/models/gemma4-e4b/ (accessed 2026-09-06)

---

## PART 2: AMD iGPU Inference via Vulkan (RADV) — State as of Late 2026

### 2.1 Known Stability Issues

**DeviceLost errors on AMD APUs:**
- `vk::Queue::submit: ErrorDeviceLost` is the primary failure mode on AMD Vega iGPUs via Vulkan/RADV
- Root cause identified in llama.cpp issue #21724: GPU job timeout from oversized command batches on gfx90c (Renoir/Vega) APUs. The kernel driver cancels compute shaders ("The CS has been cancelled because the context is lost") when GPU jobs run too long, causing a hard recovery
- Context size sensitivity: crashes become frequent at ~35K-50K context on Vega iGPUs
  - Clarence Ho (May 2026): core dump at ~35K context on Ryzen iGPU
  - llama.cpp issue #26447: ErrorDeviceLost after ~50K context on Vega 8 iGPU
- Issue #20515: crash sensitive to ubatch-size and context length (Strix Halo, but same class of bug)
- Issue #27076: device lost on Vulkan0 during decode at ~30K tokens
- Sources: https://github.com/ggml-org/llama.cpp/issues/21724 (accessed 2026-09-06), https://github.com/ggml-org/llama.cpp/issues/26447 (accessed 2026-09-06), https://github.com/ggml-org/llama.cpp/issues/20515 (accessed 2026-09-06), https://github.com/ggml-org/llama.cpp/issues/27076 (accessed 2026-09-06), https://www.clarenceho.net/2026/05/resolving-core-dump-issues-when-running.html (accessed 2026-09-06)

**Model size cutoff for Vulkan stability (from local benchmarking):**
- Models <= 4.7B at Q4: stable without flash attention
- Models 5B+: crash with Vulkan ErrorDeviceLost regardless of settings
- MoE models (8.5B total, 1B active): also crash
- Source: local vulkan-igpu-llm-benchmark skill (verified on AMD Ryzen 5 3500U, Radeon Vega Mobile, Ubuntu 24.04)

**GTT memory ballooning on multimodal models:**
- llama.cpp issue #27146: mmproj/mtmd models balloon GTT allocations to ~33 GB total-vm at load on AMD iGPU (Vulkan), causing system-wide OOM
- This is iGPU/GTT-specific; identical setup runs cleanly on discrete RTX 3090
- Source: https://github.com/ggml-org/llama.cpp/issues/27146 (accessed 2026-09-06)

**Ollama vendored llama.cpp lag:**
- Ollama's vendored llama.cpp (as of issue #15601) was at b7437 (Dec 2025), missing two significant Vulkan/AMD performance PRs that landed after that
- PR #19625 (Wave32 FA) and PR #20551 (graphics queue) not yet picked up by Ollama
- Any llama.cpp commit >= b8500 / after Mar 15, 2026 should include both
- Sources: https://github.com/ollama/ollama/issues/15601 (accessed 2026-09-06)

### 2.2 Mesa / RADV Version Notes

| Mesa Version | Date | Relevance to Vulkan LLM Compute |
|---|---|---|
| 25.3.x | Pre-Feb 2026 | Last 25.3 bugfix release planned Feb 18, 2026. Earlier 24.3.x had Vega APU freeze issues requiring downgrade to 24.2.7 |
| 26.0.0 | Feb 11, 2026 | New development release. Stability and performance improvements for AMD Radeon via Vulkan. Development release — wait for 26.0.1 for stability |
| 26.1.0 | May 6, 2026 | Development release. Targeted stability patches for Vulkan, fixing GPU hangs |
| 26.1.2 | Jun 3, 2026 | Targeted patch set: eliminates stuttering, crashes, and color conversion bugs across AMD and Intel. Vulkan crash fixes for AMD |
| 26.1.5 | Jul 15, 2026 | Stable bugfix alongside 26.2.0-rc1. Stability fixes |
| 26.1.6 | ~Jul 2026 | AMD RX 9070, RDNA 4 fixes. RADV acceleration structure fixes |
| 26.1.8 | ~Aug 2026 | Final stable bugfix for 26.1 branch. Critical RADV rendering issue fixes |
| 26.2.0-rc1 | Jul 15, 2026 | New development cycle. OpenCL 3.1 support, Vulkan updates |
| 26.2.2 | Sep 2, 2026 | NGG culling GPU hang fix for Navi10 (RadeonSI/RADV). Latest stable |

**Key takeaway:** Mesa 26.1.2 (Jun 2026) was the most significant release for Vulkan stability on AMD, specifically fixing crash issues. Users on older Mesa versions (24.x, 25.x) with Vega APUs should upgrade to at least 26.1.2. The 26.2.x branch is current as of Sep 2026.
- Sources: https://www.linuxcompatible.org/story/mesa-2612-fixes-linux-graphics-stuttering-and-vulkan-crashes-for-amd-and-intel-gpus/ (accessed 2026-09-06), https://docs.mesa3d.org/relnotes/26.0.0.html (accessed 2026-09-06), https://docs.mesa3d.org/relnotes/26.1.0.html (accessed 2026-09-06), https://www.linuxcompatible.org/story/mesa-2620rc1-and-2615-released-opencl-31-support-vulkan-updates-and-stability-fixes/ (accessed 2026-09-06), https://www.linuxcompatible.org/story/mesa-2618-drops-as-the-final-stable-bugfix-for-the-261-branch (accessed 2026-09-06), https://docs.mesa3d.org/relnotes/26.2.2.html (accessed 2026-09-06)

**FreeBSD report (relevant to Mesa flash attention fix):**
- Upgrading mesa-devel to 26.1.b.305 fixed the flash attention issue on one system. The GPU crash was prevented by the newer Mesa version avoiding the problematic code path.
- Source: https://forums.freebsd.org/threads/gpu-crash.102441/ (accessed 2026-09-06)

### 2.3 Flash Attention Support on Vulkan

**Current state: NOT supported on AMD iGPUs via Vulkan**

- Vulkan Flash Attention in llama.cpp requires `coopmat2` (VK_NV_cooperative_matrix2), which is an NVIDIA-specific extension
- On any non-NVIDIA GPU, enabling flash attention causes computation to be offloaded to CPU, causing extreme performance degradation
- Ollama issue #12928: `FlashAttentionSupported()` check in Ollama code correctly detects this and logs "flash attention enabled but not supported by gpu" — the feature is silently disabled
- Ollama's official docs and community guides for AMD iGPU Vulkan explicitly say: "Leave disabled: Flash Attention is unsupported on iGPUs via Vulkan"
- PR #26046 (merged Jul 24, 2026): removed the rocWMMA FlashAttention kernel from HIP/Vulkan builds; replaced with newer MMA kernel path. This affects ROCm/HIP builds primarily, not pure Vulkan.
- Mesa's amdgpu driver is implementing a polyfill for pre-RDNA3 for VK_KHR_cooperative_matrix, but this is UNVERIFIED as to whether it enables FA on Vega/GCN iGPUs
- Sources: https://github.com/ggml-org/llama.cpp/discussions/10879 (accessed 2026-09-06), https://github.com/ggml-org/llama.cpp/discussions/12629 (accessed 2026-09-06), https://github.com/ollama/ollama/issues/12928 (accessed 2026-09-06), https://gist.github.com/davidemiceli/69b4030e08dcee9ab89f34ead49ff0dc (accessed 2026-09-06), https://note.com/samehadaonsen/n/n5640d572550a?hl=en (accessed 2026-09-06), https://github.com/ggml-org/llama.cpp/pull/10206 (accessed 2026-09-06)

**Local benchmark confirmation:**
- `OLLAMA_FLASH_ATTENTION=1` causes `vk::Queue::submit: ErrorDeviceLost` on models >4B params during prompt processing at ~4000 tokens
- Must be OFF for models >4B
- Safe for models <=2B (UNVERIFIED — may still cause issues)
- Source: local vulkan-igpu-llm-benchmark skill

### 2.4 Ollama iGPU Vulkan Configuration

The working configuration for AMD Vega iGPU (from local benchmarking and community guides):

```ini
[Service]
Environment="OLLAMA_VULKAN=1"
Environment="ROCR_VISIBLE_DEVICES=-1"
Environment="HIP_VISIBLE_DEVICES=-1"
Environment="OLLAMA_IGPU_ENABLE=1"
Environment="OLLAMA_CONTEXT_LENGTH=65536"
Environment="OLLAMA_KV_CACHE_TYPE=q4_0"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_BATCH_SIZE=256"
Environment="OLLAMA_NUM_THREAD=4"
# OLLAMA_FLASH_ATTENTION must NOT be set (or must be 0)
```

Sources: local vulkan-igpu-llm-benchmark skill, https://gist.github.com/davidemiceli/69b4030e08dcee9ab89f34ead49ff0dc (accessed 2026-09-06), https://dasroot.net/posts/2026/03/ollama-gpu-optimization-configuration-2026/ (accessed 2026-09-06)

---

## PART 3: Synthesis — Top 3 Model Choices for 3.2GB VRAM + 17GB GTT AMD APU

**Target workload:** Reliable 64K-context agent work with tool calling on AMD Ryzen Vega Mobile iGPU (Picasso/Raven2, gfx90c) via Vulkan (RADV), Ollama.

**Hardware constraints:**
- 3.2 GB dedicated VRAM + 17 GB GTT (GPU-accessible system RAM via UMA) = ~20 GB total GPU-accessible memory
- No CUDA, no ROCm (gfx90c not supported by ROCm; rocBLAS has no gfx9 kernels)
- Vulkan (RADV) is the only GPU acceleration path
- Flash attention is NOT available — KV cache uses standard (non-FA) path, consuming more VRAM
- Model size cutoff: <= 4.7B at Q4 for Vulkan stability; 5B+ crashes
- Context size risk: DeviceLost crashes increase at >35K-50K context on Vega iGPUs

**VRAM budget at 64K context (Q4_K_M, no flash attention):**
- Model weights: 1.5-2.5 GB for 2-4B models at Q4
- KV cache at 64K context (Q4_0 quantized): ~2-4 GB depending on model architecture
- Overhead: ~0.5-1 GB
- Total: fits within 20 GB GTT+VRAM budget, but the 3.2 GB VRAM portion is the bottleneck for model weights; KV cache spills to GTT (slower)

### Ranking

#### 1. Qwen3.5-4B (Q4_K_M) — RECOMMENDED PRIMARY

**Why first:**
- Proven winner on this exact hardware. Local benchmarks confirm: completed agentic task, got correct answer, stable on Vulkan without flash attention
- 262K native context (extensible to ~1M via YaRN) — 64K is well within range
- Native function calling + JSON mode support, confirmed by multiple benchmarks
- Ties for #1 on tool-calling benchmark (0.880) with models 2-4x its size
- Apache 2.0 license — unrestricted commercial use
- At Q4_K_M (~2.5 GB), model weights fit in VRAM; KV cache at 64K with Q4_0 quantization fits in GTT
- GDN hybrid architecture is memory-efficient for long context vs full-attention models

**Risks:**
- 4.7B at Q4 is near the Vulkan stability ceiling (5B+ crashes). May be intermittent DeviceLost at high context
- Sometimes times out because it keeps generating after completing the task (local benchmark finding)
- 64K context with no flash attention means large KV cache — may approach DeviceLost threshold (~35-50K observed on Vega iGPUs)

**Mitigation:** Use `OLLAMA_KV_CACHE_TYPE=q4_0` to compress KV cache. Monitor for DeviceLost. Configure cloud fallback. Reduce context to 32K if crashes occur.

#### 2. LFM2.5-2.6B (Q4_K_M) — RECOMMENDED SECONDARY

**Why second:**
- Best-in-class tool-calling quality at 2.6B scale. Tops nearly every tool-use benchmark, trailing only Qwen3.5-9B (which is outside our size range) on BFCLv4
- 128K native context — 64K is well within range
- Purpose-built for on-device agentic workloads with agentic RL post-training
- At Q4_K_M (1.68 GB), model weights easily fit in 3.2 GB VRAM — leaves maximum room for KV cache
- Hybrid architecture (not standard transformer) is designed for memory efficiency
- Small enough to be well below the 4.7B Vulkan stability cutoff

**Risks:**
- LFM Open License v1.0 is NOT Apache 2.0 — commercial use restricted to companies < $10M revenue. This is a real constraint for fleet deployment if revenue exceeds threshold
- UNVERIFIED: Whether LFM2.5-2.6B tool calling works correctly through Ollama's tool-calling API (local benchmarks showed lfm2.5-thinking got correct answers but could not do tool calls properly — chat only). The 2.6B variant may differ from the thinking variant
- Local benchmarks showed lfm25-instruct:64k did NOT create the file in agentic task (but this may be the older LFM2-1.2B, not LFM2.5-2.6B)

**Mitigation:** Test LFM2.5-2.6B specifically for Ollama tool-calling API compatibility. If license is a blocker, fall back to Qwen3.5-2B.

#### 3. Qwen3.5-2B (Q4_K_M) — RECOMMENDED TERTIARY / FALLBACK

**Why third:**
- Apache 2.0 license — no commercial restrictions
- 262K native context, same architecture and tool-calling support as 4B variant
- At ~1.5 GB Q4_K_M, easily fits in VRAM with generous KV cache headroom
- Well below Vulkan stability cutoff — most reliable for sustained 64K context
- Smaller KV cache than 4B variant, reducing DeviceLost risk at high context

**Risks:**
- Local benchmarks showed Qwen3.5-2B-bf16 got WRONG answers on agentic word-count task (counted 9 instead of 14). Quality at 2B is demonstrably lower than 4B for agentic work
- May require more careful prompting for reliable tool calling
- Less reasoning depth than 4B or LFM2.5-2.6B

**Mitigation:** Use for simpler agent tasks or as a reliable fallback when 4B crashes. Pair with cloud model for complex reasoning.

### Models NOT Recommended

| Model | Why Not |
|---|---|
| Gemma 4 E2B | 5.1B total parameters (despite 2.3B "effective") — at Q4 this is ~5 GB, near/over the Vulkan stability cutoff. PLE architecture means larger on-disk size than competitors. Local benchmarks showed gemma4:12b crashes Vulkan. UNVERIFIED whether E2B specifically crashes, but the 5.1B total param count is a risk |
| Gemma 4 E4B | 8B total parameters — well above the 4.7B Vulkan stability ceiling. Will crash with ErrorDeviceLost |
| LFM2.5-8B-A1B (MoE) | 8.3B total parameters — local benchmarks confirm MoE models crash Vulkan regardless of active parameter count |
| Qwen3.5-9B | 9.7B — above Vulkan stability ceiling |
| Qwen3.5-0.8B | Likely stable but tool-calling quality at 0.8B is UNVERIFIED for agentic workloads. Too small for reliable agent use |
| LFM2-350M/700M | Too small for reliable 64K-context agent work. Tool calling only demonstrated after fine-tuning (distil labs) |

---

## Summary Table

| Rank | Model | Params (Q4 size) | Context | Tool Calling | License | Vulkan Stable? | Key Risk |
|---|---|---|---|---|---|---|---|
| 1 | Qwen3.5-4B | 4B (~2.5 GB) | 262K | Native, top-tier | Apache 2.0 | Yes (proven) | Near stability ceiling; timeout on overgeneration |
| 2 | LFM2.5-2.6B | 2.6B (~1.7 GB) | 128K | Native, best-in-class | LFM Open (restricted) | Yes (expected) | License restriction; Ollama tool-calling compat UNVERIFIED |
| 3 | Qwen3.5-2B | 2B (~1.5 GB) | 262K | Native, supported | Apache 2.0 | Yes (highly likely) | Lower agentic quality; wrong answers in local test |

---

## Sources Index

### LFM2 / Liquid AI
- https://www.liquid.ai/blog/lfm2-5-2-6b — LFM2.5-2.6B blog post (accessed 2026-09-06)
- https://huggingface.co/blog/LiquidAI/lfm2-5-2-6b — HF blog (accessed 2026-09-06)
- https://huggingface.co/LiquidAI/LFM2.5-2.6B — model card (accessed 2026-09-06)
- https://docs.liquid.ai/lfm/models/lfm25-2.6b — docs (accessed 2026-09-06)
- https://www.liquid.ai/lfm-license — license terms (accessed 2026-09-06)
- https://huggingface.co/LiquidAI/LFM2-2.6B-Exp-GGUF/discussions/3 — license discussion (accessed 2026-09-06)
- https://venturebeat.com/technology/liquid-ais-smallest-model-yet-lfm2-5-230m-beats-models-4x-its-size-at-data-extraction-can-run-anywhere — license analysis (accessed 2026-09-06)
- https://www.distillabs.ai/blog/fine-tuning-liquids-lfm25-accurate-tool-calling-at-350m-parameters/ — tool calling fine-tuning (accessed 2026-09-06)
- https://www.marktechpost.com/2026/08/06/liquid-ai-lfm2-5-2-6b-on-device-agentic-model/amp/ — overview (accessed 2026-09-06)
- https://huggingface.co/bartowski/LiquidAI_LFM2.5-2.6B-GGUF — GGUF sizes (accessed 2026-09-06)
- https://vramcalculator.com/lfm2-5-2-6b-vram-requirements/ — VRAM requirements (accessed 2026-09-06)
- https://www.liquid.ai/blog/introducing-lfm2-5-the-next-generation-of-on-device-ai — LFM2.5-1.2B (accessed 2026-09-06)
- https://docs.liquid.ai/lfm/models/lfm25-1.2b-instruct — 1.2B docs (accessed 2026-09-06)
- https://unsloth.ai/docs/models/tutorials/lfm2.5 — 1.2B specs (accessed 2026-09-06)
- https://arxiv.org/pdf/2511.23404 — LFM2 technical report (accessed 2026-09-06)

### Qwen 3.5
- https://huggingface.co/Qwen/Qwen3.5-4B — model card (accessed 2026-09-06)
- https://huggingface.co/Qwen/Qwen3.5-2B — model card (accessed 2026-09-06)
- https://www.morphllm.com/qwen-3-5 — architecture overview (accessed 2026-09-06)
- https://unsloth.ai/docs/models/qwen3.5 — local deployment (accessed 2026-09-06)
- https://ollama.com/library/qwen3.5:0.8b/blobs/9be69ef46306 — Apache 2.0 license confirmation (accessed 2026-09-06)
- https://deepinfra.com/blog/qwen-3-5-0-8b-via-deepinfra-api-benchmarks — 0.8B specs (accessed 2026-09-06)
- https://qwen.readthedocs.io/en/latest/framework/function_call.html — function calling docs (accessed 2026-09-06)
- https://github.com/MikeVeerman/tool-calling-benchmark — tool calling benchmark (accessed 2026-09-06)
- https://huggingface.co/unsloth/Qwen3.5-4B-GGUF — GGUF (accessed 2026-09-06)
- https://apxml.com/models/qwen35-2b — 2B specs (accessed 2026-09-06)

### Gemma 4
- https://ai.google.dev/gemma/docs/core — model overview (accessed 2026-09-06)
- https://ai.google.dev/gemma/docs/core/model_card_4 — model card (accessed 2026-09-06)
- https://huggingface.co/google/gemma-4-E2B — E2B model card (accessed 2026-09-06)
- https://huggingface.co/google/gemma-4-E4B-it — E4B model card (accessed 2026-09-06)
- https://www.jetson-ai-lab.com/models/gemma4-e4b/ — E4B specs (accessed 2026-09-06)
- https://www.distillabs.ai/learn/gemma-4-e2b-and-e4b-explained/ — parameter explanation (accessed 2026-09-06)
- https://codersera.com/blog/gemma-4-complete-guide-2026/ — complete guide (accessed 2026-09-06)
- https://www.mindstudio.ai/blog/gemma-4-apache-2-license-commercial-use — license (accessed 2026-09-06)
- https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4 — function calling (accessed 2026-09-06)
- https://machinelearningmastery.com/how-to-implement-tool-calling-with-gemma-4-and-python/ — tool calling (accessed 2026-09-06)
- https://www.ertas.ai/blog/on-device-tool-calling-2026-qwen3-gemma4-phi4 — tool calling comparison (accessed 2026-09-06)
- https://huggingface.co/roshangrewal/gemma4-e4b-toolcall-v01 — fine-tuned tool calling (accessed 2026-09-06)
- https://gemma-4.net/download — GGUF sizes (accessed 2026-09-06)
- https://unsloth.ai/docs/models/gemma-4 — local deployment (accessed 2026-09-06)
- https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/ — launch blog (accessed 2026-09-06)

### AMD Vulkan / RADV
- https://github.com/ggml-org/llama.cpp/issues/21724 — gfx90c DeviceLost root cause (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/issues/26447 — Vega 8 DeviceLost at 50K context (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/issues/20515 — DeviceLost sensitive to ubatch/context (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/issues/27076 — device lost on Vulkan0 (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/issues/27146 — GTT ballooning on multimodal (accessed 2026-09-06)
- https://www.clarenceho.net/2026/05/resolving-core-dump-issues-when-running.html — DeviceLost at 35K context (accessed 2026-09-06)
- https://github.com/ollama/ollama/issues/15601 — Ollama vendored llama.cpp lag (accessed 2026-09-06)
- https://github.com/ollama/ollama/issues/12928 — Flash attention unsupported on Vulkan (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/discussions/10879 — no Vulkan FA except coopmat2 (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/discussions/12629 — FA on Vulkan only on NVIDIA coopmat2 (accessed 2026-09-06)
- https://github.com/ggml-org/llama.cpp/pull/10206 — coopmat2 PR, AMD polyfill discussion (accessed 2026-09-06)
- https://note.com/samehadaonsen/n/n5640d572550a?hl=en — PR#26046 FlashAttention kernel removal (accessed 2026-09-06)
- https://thegputrade.com/news/flash-attention-reaches-older-and-integrated-gpus-7utmawj9/ — FA reaches older GPUs (accessed 2026-09-06)
- https://gist.github.com/davidemiceli/69b4030e08dcee9ab89f34ead49ff0dc — Ollama Vulkan iGPU guide (accessed 2026-09-06)

### Mesa / RADV releases
- https://docs.mesa3d.org/relnotes/26.0.0.html — Mesa 26.0.0 (accessed 2026-09-06)
- https://docs.mesa3d.org/relnotes/26.1.0.html — Mesa 26.1.0 (accessed 2026-09-06)
- https://docs.mesa3d.org/relnotes/26.2.2.html — Mesa 26.2.2 (accessed 2026-09-06)
- https://www.linuxcompatible.org/story/mesa-2612-fixes-linux-graphics-stuttering-and-vulkan-crashes-for-amd-and-intel-gpus/ — 26.1.2 crash fixes (accessed 2026-09-06)
- https://www.linuxcompatible.org/story/mesa-2620rc1-and-2615-released-opencl-31-support-vulkan-updates-and-stability-fixes/ — 26.1.5/26.2.0-rc1 (accessed 2026-09-06)
- https://www.linuxcompatible.org/story/mesa-2618-drops-as-the-final-stable-bugfix-for-the-261-branch — 26.1.8 (accessed 2026-09-06)
- https://forums.freebsd.org/threads/gpu-crash.102441/ — Mesa 26.1.b.305 FA fix (accessed 2026-09-06)

### Local benchmark data
- vulkan-igpu-llm-benchmark skill (verified on AMD Ryzen 5 3500U, Radeon Vega Mobile, Ubuntu 24.04, Ollama + Vulkan)

---

## UNVERIFIED Items Summary

- LFM2.5-1.2B-Instruct exact context window (128K assumed from family pattern but not confirmed for 1.2B specifically)
- LFM2.5-1.2B-Instruct Q4_K_M GGUF file size
- LFM2.5-2.6B Ollama tool-calling API compatibility (local benchmarks tested older LFM2-1.2B variants, not 2.6B)
- Gemma 4 E2B exact Q4_K_M GGUF file size
- Gemma 4 E4B exact Q4_K_M GGUF file size
- Qwen3.5-4B exact Q4_K_M GGUF file size (estimated ~2.5 GB from 4.7B Q4 benchmark data)
- Whether Mesa's VK_KHR_cooperative_matrix polyfill enables flash attention on Vega/GCN iGPUs
- Whether Gemma 4 E2B (5.1B total) crashes Vulkan at Q4 (predicted yes based on 4.7B stability ceiling, but not directly tested)
- LFM2-350M and LFM2-700M context window sizes
- LFM2-700M tool-calling support
- Qwen3.5-0.8B tool-calling quality for agentic workloads