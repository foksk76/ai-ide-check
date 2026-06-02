# Reverse Engineering Model Evaluation: Future Direction

## Status

Idea backlog for a future project track.

The current project focus remains local coder-agent evaluation. Reverse
engineering must be developed as a separate track with its own fixtures,
metrics, artifacts, and safety boundaries.

## Confirmed Intent

Build an isolated learning lab for practicing vulnerability research with AI
assistance.

The starting point is a virtual firmware image deployed on a Proxmox VE stand.
There is no single fixed scenario. The investigation should branch as evidence
appears: run the most likely checks first, deepen the analysis when a signal is
found, and record why each next step was selected.

Use local models for routine work and cloud models for difficult cases. Treat
model output as a hypothesis until it is confirmed by a reproducible check.

Before deploying a sample or running a dynamic test, request access to the
isolated stand explicitly.

## Purpose

Evaluate whether local models can make authorized binary analysis more
repeatable and useful:

- improve decompiler output
- explain recovered function behavior
- propose meaningful identifiers
- identify suspicious code paths for human review
- preserve evidence instead of replacing it with confident guesses

This is not a promise of lossless source recovery. Compilation removes
information. A useful result is a tested approximation with recorded evidence.

The learning goal is broader than decompilation: practice the complete
defensive path from an unfamiliar firmware image to a confirmed finding and a
reviewable security patch.

## Three Independent Directions

Keep three evaluation tracks separate. They may cooperate in one investigation,
but success in one track does not prove success in another.

| Direction | Question | Evidence |
|---|---|---|
| Assembly-to-C decompilation | Can a specialized model recover useful C-like code directly from disassembly? | Recompilation and behavioral tests where practical |
| Ghidra pseudo-code refinement | Can a specialized model turn Ghidra output into clearer, more useful code without inventing behavior? | Diff review, recompilation, and behavioral tests |
| Agentic behavior analysis | Can a model inspect evidence, select the next bounded check, explain a suspected weakness, and assist with a defensive patch? | Recorded tool calls, reproduced finding, external tests, and human review |

The first useful path should probably start with Ghidra pseudo-code refinement:
it uses a mature static-analysis tool as a foundation and gives a shorter route
to reviewable evidence. Direct assembly-to-C recovery remains a comparison
track, not a prerequisite.

## Proposed Quest Loop

```text
virtual firmware image on the isolated stand
  -> inventory and static triage
  -> choose the most probable next check
  -> disassembly and Ghidra pseudo-code
  -> specialized decompilation or refinement model
  -> local analysis model for routine investigation
  -> cloud model escalation for difficult cases when needed
  -> request access before deployment or dynamic testing
  -> reproduce or reject the hypothesis on the isolated stand
  -> defensive patch and regression checks
  -> evidence bundle and next quest branch
```

Use Ghidra as the first static-analysis tool because it is open source and can
be automated. Keep the stages separate: a model specialized in translating
assembly or Ghidra pseudo-C should not automatically be treated as a capable
repository agent.

The quest can include controlled analysis of ransomware behavior and other
hostile patterns inside the isolated lab. The objective is detection,
explanation, confirmation, and defensive patching.

## Candidate Roles

### Specialized Decompilation

Start with the open [LLM4Decompile](https://github.com/albertan017/LLM4Decompile)
family:

| Candidate | Intended role | Initial decision |
|---|---|---|
| [`LLM4Binary/llm4decompile-6.7b-v2`](https://huggingface.co/LLM4Binary/llm4decompile-6.7b-v2) | Improve Ghidra pseudo-code or recover C-like code from assembly | First local candidate |
| [`LLM4Binary/llm4decompile-9b-v2`](https://huggingface.co/LLM4Binary/llm4decompile-9b-v2) | Heavier comparison point | Add after the 6.7B baseline |
| [`LLM4Binary/llm4decompile-1.3b-v1.6`](https://huggingface.co/LLM4Binary/llm4decompile-1.3b-v1.6) | Fast low-cost control | Optional control |
| [`LLM4Binary/sk2decompile-struct-6.7b`](https://huggingface.co/LLM4Binary/models) | Recover function structure | Later experiment |
| [`LLM4Binary/sk2decompile-ident-6.7b`](https://huggingface.co/LLM4Binary/sk2decompile-ident-6.7b) | Recover readable identifiers | Later experiment |

The 6.7B model has community GGUF conversions, including
[`Q4_K_M`](https://huggingface.co/tensorblock/llm4decompile-6.7b-v2-GGUF).
Ollama supports [importing GGUF models](https://docs.ollama.com/import), so a
local RX 6800 experiment is feasible without adding a second inference server.

### Analysis And Tool Orchestration

Use a general model after decompilation to inspect evidence and drive bounded
tools:

| Candidate | Reason to include |
|---|---|
| `gpt-oss:20b-ctx32k` | Current Windows coder-track leader; already passed local structured-tool and repository-editing gates |
| [`rnj-1:8b`](https://ollama.com/library/rnj-1) | Compact Ollama model aimed at code, STEM, tool calling, and agent workflows |
| [`ministral-3:8b`](https://ollama.com/library/ministral-3) | Existing lightweight local comparison point; the tuned `ctx32k` profile passed the first Windows coder fixture |
| [`ministral-3:14b`](https://ollama.com/library/ministral-3) | Installed deeper-analysis candidate; require a tuned `ctx32k` placement gate before expensive runs |
| [`deepseek-coder-v2:16b`](https://ollama.com/library/deepseek-coder-v2) | Code-focused MoE comparison point for low-level code reading |

Treat cybersecurity-focused community models as exploratory only. Before use,
record their origin, license, digest, prompt template, and local isolation
rules.

## First Bounded Quest

Use the virtual firmware image on the Proxmox VE stand as the starting point.
Do not assume the first vulnerability class in advance. Begin with probable,
low-cost checks and branch according to evidence.

Suggested first loop:

1. Record firmware identity, origin, digest, and stand snapshot.
2. Perform static inventory and triage without executing the image.
3. Rank the next checks by probability, cost, and expected learning value.
4. Use Ghidra to inspect the most relevant functions.
5. Compare raw pseudo-code with specialized-model refinement.
6. Ask a local analysis model to explain the evidence and propose the next
   bounded check.
7. Escalate a difficult branch to a cloud model only when local analysis is not
   sufficient.
8. Request explicit stand access before deployment or dynamic testing.
9. Reproduce or reject the suspected weakness in the isolated environment.
10. Prepare a defensive patch and run regression checks where practical.

Maintain small owned C fixtures alongside the firmware quest. They remain
useful as calibration samples for testing decompilation quality independently
from a changing investigation.

Potential quest branches include:

- unsafe memory operations
- authentication and authorization mistakes
- unsafe update or configuration handling
- weak cryptographic usage
- suspicious file modification or encryption behavior
- persistence and unexpected process execution
- patch development and regression testing

## Initial Metrics

| Metric | Why it matters |
|---|---|
| Compiles successfully | Recovered code can be checked mechanically |
| Behavioral tests passed | Similar-looking code is not enough |
| Identifier usefulness | Human review becomes faster |
| Explanation accuracy | The analysis model must remain grounded in evidence |
| Unsupported claims | Hallucinated behavior must be counted explicitly |
| Elapsed time | Local usefulness includes latency |
| Processor placement | Preserve the stand-specific `100% GPU` evidence where applicable |
| Next-check usefulness | The proposed branch should reduce uncertainty |
| Local-to-cloud escalation | Cloud use should be deliberate and recorded |
| Reproduction result | A suspected weakness becomes a finding only after confirmation |
| Patch regression result | A defensive change must not silently break expected behavior |

Use [Decompile-Bench](https://arxiv.org/abs/2505.12668) later as an external
reference. Its million-scale binary-source pairs are useful for broader
comparison, but a small transparent local fixture should come first.

## Artifact Layout

Keep raw evidence out of Git by default:

```text
.artifacts/reverse-engineering/
  <run-stamp>/
    manifest.json
    binaries/
    ghidra/
    model-output/
    rebuilt/
    test-results/
```

Promote only concise, reviewed findings into:

```text
docs/runbooks/runs/
```

## Safety And Legal Boundary

Keep all active experiments inside the isolated lab. The lab may contain
intentionally vulnerable firmware, controlled hostile samples, dynamic
analysis, and defensive patching exercises.

Out of scope:

- impact outside the isolated stand
- analysis of external systems without authorization
- treating a model statement as a confirmed finding without reproducible
  evidence

Before deployment or dynamic testing:

```text
REQUEST STAND ACCESS
```

Keep tool execution isolated. Treat binaries, strings, pseudo-code, and model
output as untrusted input. A model may recommend actions, but external checks
must determine whether a finding is reproducible and a patch behaves correctly.

## Source-Driven Notes

| Decision | Source-backed finding | Status |
|---|---|---|
| Use Ghidra as the first static-analysis tool | The official Ghidra repository describes disassembly, decompilation, scripting, and automated execution modes | Verified |
| Automate static analysis before dynamic execution | Ghidra provides the `AnalyzeHeadless` entry point for headless processing | Verified |
| Import a GGUF decompilation model into Ollama | Ollama documents `FROM /path/to/file.gguf` in a `Modelfile`, followed by `ollama create` | Verified |
| Separate assembly-to-C and pseudo-code refinement | The LLM4Decompile repository distinguishes assembly prompt input and `LLM4Decompile-Ref`, which refines Ghidra pseudo-code | Verified |
| Start the lab with pseudo-code refinement | This is a project decision intended to shorten the route to reviewable evidence | Project hypothesis |
| Use local models for routine checks and cloud models for hard branches | This is a lab operating rule that still needs measured thresholds | Project hypothesis |

## Open Questions

- What is the exact Proxmox VE stand identity and access procedure?
- Which virtual firmware image starts the first quest?
- Should the first runner use Ghidra headless mode directly or accept exported
  pseudo-C files before full automation is added?
- Is assembly-to-C recovery useful enough to keep, or should the first useful
  workflow focus on refining Ghidra output?
- Should analysis-model tool access remain read-only until the fixture format
  stabilizes?
- What measurable signal triggers escalation from a local model to a cloud
  model?
- Which owned C fixtures should calibrate decompilation quality between quest
  stages?

## References

- [LLM4Decompile paper](https://arxiv.org/abs/2403.05286)
- [LLM4Decompile repository](https://github.com/albertan017/LLM4Decompile)
- [Decompile-Bench paper](https://arxiv.org/abs/2505.12668)
- [Ghidra official repository](https://github.com/NationalSecurityAgency/ghidra)
- [Ghidra `AnalyzeHeadless` source](https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/Features/Base/src/main/java/ghidra/app/util/headless/AnalyzeHeadless.java)
- [Ollama GGUF import documentation](https://docs.ollama.com/import)
- [Ollama `Modelfile` reference](https://docs.ollama.com/modelfile)
