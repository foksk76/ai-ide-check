## 0001: Optimize Gemma Modelfiles for Agentic Workflows

**Status**: Accepted
**Date**: 2026-06-09

### Context
During evaluation of the gemma4:12b-it-qat model, we observed significant performance degradation and frequent timeouts during multi-step agent tasks (e.g., merge_ranges). The primary issues were:
1. **Slow First Byte**: Long delays before the first token was generated, often exceeding 60 seconds.
2. **Resource Fragmentation**: Issues with GPU/CPU balance when using default configurations.

### Decision
We will adopt a standardized "Optimized" Modelfile profile for Gemma series models (specifically gemma4_12b-it-qat) to ensure stability in agentic workflows. 

The optimization includes:
- **num_ctx**: Fixed at 32,768 to stabilize memory usage and improve inference speed.
- **num_gpu**: Forced to 99 (or sufficient value) to ensure 100% GPU utilization.
- **Temperature/Top_P**: Lowered to 0.7 / 0.9 respectively to provide more deterministic tool selection.

### Consequences
- **Pros**: 
    - Significant reduction in 'Slow First Byte' occurrences.
    - Improved reliability for 	ool and gent stages in the headless pipeline.
    - Demonstrated improvement in speed (e.g., ~12% faster on 
ormalize_tags).
- **Cons**: 
    - Requires a manual ollama create step to update the model profile in the local environment.
