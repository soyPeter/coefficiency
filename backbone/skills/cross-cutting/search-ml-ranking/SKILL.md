<!-- FRAMEWORK: PYTHON -->
---
framework: python
name: search-ml-ranking
description: End-to-end search ML patterns with Tantivy, e5-small embeddings, and CatBoost YetiRank. Use when building semantic search, learning-to-rank, or optimizing search relevance.
origin: agentic-backbone
version: "1.0"
---

# Search ML Ranking Patterns

Production patterns for building semantic search engines with Tantivy, embeddings, and learning-to-rank.

## When to Use

- Building product catalog or e-commerce search
- Implementing semantic/embedding-based retrieval
- Training a learning-to-rank model
- Optimizing search relevance with offline metrics
- Project type: `search`, `ml-ranking`, `retrieval`, `ltr`

## Stack

| Component | Technology | Why |
|-----------|------------|-----|
| Lexical | tantivy-py | In-process, ~20MB RAM, no cluster |
| Embeddings | intfloat/multilingual-e5-small ONNX INT8 | 384d, CPU, 5ms encode |
| LTR | CatBoost YetiRank | Best offline MRR in competitions |
| Inference | onnxruntime | CPU, INT8 quantization |

## Performance Budgets (p99 Latency)

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

## Decision Frameworks

### D1: Búsqueda híbrida vs solo lexical / solo semántica
- ¿Vocabulario cerrado y usuarios usan términos exactos? → Solo lexical
- ¿Usuarios usan lenguaje natural, sinónimos? → Híbrido desde día 1
- ¿>5% de consultas sin resultados con solo lexical? → Híbrido obligatorio

### D2: Índice maestro + bitsets vs índice por tenant
- ¿Catálogo común a todos los tenants? → Índice maestro + bitsets
- ¿Catálogo radicalmente distinto por tenant? → Índices separados
- ¿<100.000 documentos total? → Bitsets prácticamente seguro

### D3: Walk-forward vs random CV
- ¿Datos con dimensión temporal (clics, ventas)? → Walk-forward obligatorio
- ¿Validando modelo de ranking sobre datos de comportamiento? → Walk-forward sin excepción
- ¿Random CV en este contexto? → Nunca

### D4: IPW + exploración
- ¿Entrenas un modelo a partir de clics? → IPW obligatorio
- ¿Productos nuevos necesitan oportunidad? → Exploración 5% en posiciones [3, 5, 7]
- ¿No tienes log de impresiones? → Reconstruirlo. Sin él no puedes hacer IPW correcto.

### D5: Guardrail automático en deploy
- ¿Despliegues automáticos? → Guardrail obligatorio
- ¿Tráfico crítico? → −2% umbral estricto
- ¿Ventana humana antes del deploy? → Sí, mínimo 1 hora

## Claude Code Prompts

### Phase 0: EDA

```
Analiza los datos de catálogo y de consultas en data/raw/. Responde con números:
- Cuántas palabras tiene la consulta media
- Qué porcentaje contiene tildes
- Cuál es el vocabulario activo
- Cuántas consultas distintas hay
- Qué porcentaje de consultas no devuelve resultados con BM25 baseline
Genera data/processed/eda.json con todas las métricas.
```

### Phase 1: BM25 Baseline

```
Implementa BM25 sobre Tantivy en src/bm25_index.py. Construye ground truth
desde los clics: para cada query, el producto más clicado es el resultado ideal.
Ejecuta grid search sobre k1 ∈ {0.1, 0.3, 0.5, 0.8, 1.0, 1.2, 1.5} y
b ∈ {0.0, 0.25, 0.5, 0.75, 1.0}. Reporta MRR y NDCG@10 para cada combinación.
Guarda en data/evaluations/phase1_grid.json.
```

### Phase 2: Semantic Layer

```
Compara tres modelos de embeddings: intfloat/multilingual-e5-small,
intfloat/multilingual-e5-base y BAAI/bge-m3. Para cada uno, calcula MRR y
NDCG@10 (a) usando solo embeddings, (b) usando híbrido con RRF k=60.
Mide latencia de encoding p99 en CPU con ONNX Runtime INT8.
Guarda en data/evaluations/phase2_embeddings.json.
```

### Phase 3: Learning-to-Rank

```
Define las features en config/feature_spec.json (BM25 score, embedding similarity,
popularity, recency, has_bm25, etc.). Genera training data con IPW
(weight = 1/log2(pos+1)) y skip-above. Entrena 5 modelos: CatBoost YetiRank,
XGBoost, LightGBM con LambdaRank, una baseline pointwise y una listwise.
Usa 5-fold CV walk-forward (3 semanas train, 1 semana test).
Reporta MRR ± std, NDCG@10 ± std, feature importance, latencia de inferencia.
Guarda en data/evaluations/phase3_ltr.json.
```

## ML Rules

| Rule | Description |
|------|-------------|
| IPW | `weight = 1 / log2(position + 1)` mandatory for click-based retraining |
| Walk-forward CV | Never random shuffle for temporal data |
| Golden set | 500 queries with manual judgments, never modify |
| Guardrail | Reject model if MRR/NDCG falls >2% |
| Exploration | 5% of queries get random results in positions [3, 5, 7] |
| Min clicks | 50,000 clicks minimum for retrain |

## Architecture Constraints (A1-A10)

For ML/AI search projects, these rules are **non-negotiable**:

| Rule | Constraint |
|------|------------|
| A1 | Tantivy embebido, no Elasticsearch/OpenSearch |
| A2 | Embeddings en RAM (NumPy), no vector DB (Pinecone, etc.) |
| A3 | UN índice maestro + bitsets por tenant, NO índice por tenant |
| A4 | CatBoost YetiRank, no XGBoost/LightGBM sin competición |
| A5 | e5-small (384d), no e5-base |
| A6 | BM25 con b=0 para documentos cortos |
| A7 | NO motor de reglas sobre LTR (excepto hide rule) |
| A8 | Fuzzy contra índice, no SymSpell genérico |
| A9 | UN idioma por release, validar MRR >0.60 antes de añadir más |
| A10 | Artefactos ML en object storage, no en imagen Docker |

## Metrics

### Offline Quality
- **MRR@10**: Mean Reciprocal Rank — position of first relevant result
- **NDCG@10**: Normalized Discounted Cumulative Gain — quality of top-10 ordering
- **Recall@50**: Is relevant doc in top-50?
- **No-results rate**: % queries with zero results (target <2%)

### Online Quality
- **CTR top-3**: % searches with click on positions 1-3
- **Deep scroll rate**: % searches with click beyond position 21
- **Reformulation rate**: % searches reformulated by user

## Reference Implementations

See `reference.md` for complete Python implementations:
- `src/eda.py` — EDA script
- `src/bm25_index.py` — Tantivy BM25 with grid search
- `src/embeddings.py` — e5-small ONNX + RRF fusion
- `src/ltr_train.py` — CatBoost YetiRank training with IPW
- `src/ltr_serving.py` — LTR inference pipeline
- `src/benchmark.py` — Latency benchmark for CI/CD
- `src/logging.py` — Structured JSON logger
- `src/metrics.py` — MRR, NDCG@10, Recall@50, CTR metrics