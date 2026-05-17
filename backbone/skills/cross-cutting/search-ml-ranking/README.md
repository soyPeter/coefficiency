# Search ML Ranking Skill

> End-to-end patterns for building semantic search engines with Tantivy, embeddings, and learning-to-rank

## What It Does

Builds production search systems with:
- Tantivy-based lexical search (BM25)
- e5-small embeddings with ONNX Runtime INT8 inference
- CatBoost YetiRank for learning-to-rank
- Strict latency budgets (p99 <15ms total pipeline)

## When to Use

- Building a product search or catalog search
- Implementing semantic/embedding-based retrieval
- Training a learning-to-rank model
- Optimizing search relevance with offline metrics

## Key Concepts

### Stack

| Component | Technology | Why |
|-----------|------------|-----|
| Lexical | tantivy-py | In-process, ~20MB RAM, no cluster |
| Embeddings | intfloat/multilingual-e5-small ONNX INT8 | 384d, CPU, 5ms encode |
| LTR | CatBoost YetiRank | Best offline MRR in competitions |
| Inference | onnxruntime | CPU, INT8 quantization |

### Performance Budgets

| Component | Budget |
|-----------|--------|
| Normalization | 0.5 ms |
| BM25 retrieval (top-100) | 3 ms |
| Embedding encode | 5 ms |
| Cosine similarity | 1 ms |
| Merge RRF + filter | 1 ms |
| Feature computation | 1 ms |
| CatBoost predict | 1 ms |
| JSON serialization | 0.5 ms |
| **Total** | **15 ms** |

## Project Phases

| Phase | Goal | Output |
|-------|------|--------|
| 0 | Catalog/Query EDA | `data/processed/eda.json` |
| 1 | BM25 baseline + grid search | `data/evaluations/phase1_grid.json` |
| 2 | Semantic layer + model comparison | `data/evaluations/phase2_embeddings.json` |
| 3 | Learning-to-rank with competition | `data/evaluations/phase3_ltr.json` |

## ML Rules

- **IPW mandatory**: `weight = 1 / log2(position + 1)`
- **Walk-forward CV**: Never random shuffle for temporal data
- **Golden set**: 500 queries with manual judgments
- **Guardrail**: Reject model if MRR/NDCG falls >2%
- **Exploration**: 5% of queries get random results in positions [3, 5, 7]

## Related Skills

- `architecture-review` — System design
- `performance` — Latency optimization
- `ai-guardrails` — PII redaction, content filtering

## References

- [SearchMO Playbook (Mercadona Tech)](https://github.com/mercadona/sociedad)
- [Tantivy](https://github.com/quickwit-oss/tantivy)
- [ONNX Runtime](https://onnxruntime.ai/)
- [CatBoost](https://catboost.ai/)