<!-- FRAMEWORK: PYTHON -->
---
framework: python
name: search-ml-ranking-reference
description: Reference implementations for search ML ranking. See SKILL.md for guidance.
origin: agentic-backbone
version: "1.0"
---

# Search ML Ranking — Reference Implementations

*This file contains the complete Python implementations referenced in the main SKILL.md.*
*See SKILL.md for guidance, decision frameworks, and Claude Code prompts.*

## Stack

```python
# requirements.txt
tantivy==0.22.0          # Lexical search (MIT)
onnxruntime==1.19.0      # ONNX inference (MIT)
onnx==1.17.0             # ONNX model format
numpy==1.26.0            # Numerical computing (BSD)
scikit-learn==1.5.0      # ML utilities (BSD)
catboost==1.2.5          # LTR model (Apache 2.0)
pandas==2.2.0            # Data handling
pyarrow==16.0.0          # Parquet support
```

## Phase 0: EDA Script

```python
# src/eda.py
"""Phase 0: Exploratory Data Analysis of catalog and queries."""

import json
import pandas as pd
from pathlib import Path
from collections import Counter
import unicodedata


def normalize_query(query: str) -> str:
    """Unicode normalization + lowercase + tokenize."""
    return unicodedata.normalize('NFD', query.lower().strip())


def analyze_queries(queries_path: Path) -> dict:
    """Analyze query distribution."""
    queries = pd.read_parquet(queries_path)

    lengths = queries['query'].str.split().str.len()
    has_accents = queries['query'].str.contains('[áéíóúñü]', regex=True)
    vocab = Counter(queries['query'].str.lower().str.split().explode())

    return {
        'total_queries': len(queries),
        'unique_queries': queries['query'].nunique(),
        'avg_words': lengths.mean(),
        'median_words': lengths.median(),
        'p95_words': lengths.quantile(0.95),
        'pct_with_accents': has_accents.mean(),
        'vocabulary_size': len(vocab),
        'top_10_words': vocab.most_common(10),
    }


def analyze_catalog(catalog_path: Path) -> dict:
    """Analyze catalog structure."""
    catalog = pd.read_parquet(catalog_path)

    desc_lengths = catalog.get('description', catalog.get('name', '')).str.split().str.len()

    return {
        'total_documents': len(catalog),
        'avg_description_words': desc_lengths.mean(),
        'p50_description_words': desc_lengths.quantile(0.5),
        'p95_description_words': desc_lengths.quantile(0.95),
        'columns': list(catalog.columns),
    }


def main():
    data_dir = Path('data/raw')
    output_dir = Path('data/processed')
    output_dir.mkdir(parents=True, exist_ok=True)

    eda = {
        'queries': analyze_queries(data_dir / 'queries.parquet'),
        'catalog': analyze_catalog(data_dir / 'catalog.parquet'),
    }

    with open(output_dir / 'eda.json', 'w') as f:
        json.dump(eda, f, indent=2, default=str)

    print(f"EDA saved to {output_dir / 'eda.json'}")
```

## Phase 1: Tantivy BM25 Index

```python
# src/bm25_index.py
"""Phase 1: Tantivy BM25 index with grid search."""

import json
import numpy as np
import pandas as pd
from pathlib import Path
from tantivy import Document, Index, Schema, TextField, U64Field
from tantivy.queryparser import QueryParser
from collections import defaultdict


BM25_K1_RANGE = [0.1, 0.3, 0.5, 0.8, 1.0, 1.2, 1.5]
BM25_B_RANGE = [0.0, 0.25, 0.5, 0.75, 1.0]


def create_schema() -> Schema:
    """Create Tantivy schema for product catalog."""
    return Schema.builder().add(
        TextField("id", stored=True),
        TextField("name", stored=True),
        TextField("description", stored=True),
        TextField("category", stored=True),
        U64Field("popularity", stored=True),
    ).build()


def build_index(catalog: pd.DataFrame, index_path: Path) -> Index:
    """Build Tantivy index from catalog DataFrame."""
    schema = create_schema()
    index = Index.create_in_dir(index_path, schema)
    writer = index.writer()

    for _, row in catalog.iterrows():
        doc = Document(
            id=str(row['id']),
            name=str(row['name']),
            description=str(row.get('description', '')),
            category=str(row.get('category', '')),
            popularity=int(row.get('popularity', 0)),
        )
        writer.add_document(doc)

    writer.commit()
    return index


def search(
    index: Index,
    query: str,
    top_k: int = 100,
    k1: float = 0.5,
    b: float = 0.0,
) -> list[tuple[str, float]]:
    """Search index with BM25 scoring."""
    searcher = index.searcher()
    query_parser = QueryParser.for_index(index, ["name", "description"])
    parsed_query = query_parser.parse_query(query)
    scored_docs = searcher.search(parsed_query, top_k).hits
    return [(doc_id, score) for doc_id, score in scored_docs]


def compute_mrr(predictions: list[str], ground_truth: dict[str, str]) -> float:
    """Mean Reciprocal Rank."""
    mrr = 0.0
    for query, true_doc in ground_truth.items():
        for rank, (doc_id, _) in enumerate(predictions[:10], 1):
            if doc_id == true_doc:
                mrr += 1.0 / rank
                break
    return mrr / len(ground_truth) if ground_truth else 0.0


def compute_ndcg(predictions: list[str], ground_truth: dict[str, list[str]]) -> float:
    """NDCG@10."""
    def dcg(relevance: list[int], k: int = 10) -> float:
        return sum((2**r - 1) / np.log2(i + 2) for i, r in enumerate(relevance[:k]))

    dcg_scores = []
    for query, relevant_docs in ground_truth.items():
        relevance = [1 if doc_id in relevant_docs else 0 for doc_id, _ in predictions[:10]]
        dcg_scores.append(dcg(relevance))

    ideal_relevance = [1] * min(10, len(relevant_docs))
    idcg = dcg(ideal_relevance)

    return np.mean(dcg_scores) / idcg if idcg > 0 else 0.0


def grid_search(
    index: Index,
    ground_truth: dict[str, str],
    queries: list[str],
) -> dict:
    """Grid search over BM25 k1 and b parameters."""
    results = []

    for k1 in BM25_K1_RANGE:
        for b in BM25_B_RANGE:
            mrr_scores = []

            for query in queries:
                preds = search(index, query, top_k=10, k1=k1, b=b)
                mrr = compute_mrr([p[0] for p in preds], {query: ground_truth[query]})
                mrr_scores.append(mrr)

            results.append({
                'k1': k1,
                'b': b,
                'mrr': np.mean(mrr_scores),
                'mrr_std': np.std(mrr_scores),
            })

    return {'grid_results': results, 'best': max(results, key=lambda x: x['mrr'])}


def main():
    data_dir = Path('data')
    output_dir = data_dir / 'evaluations'
    output_dir.mkdir(parents=True, exist_ok=True)

    catalog = pd.read_parquet(data_dir / 'raw' / 'catalog.parquet')
    clicks = pd.read_parquet(data_dir / 'raw' / 'clicks.parquet')

    ground_truth = (
        clicks.groupby('query')['doc_id']
        .agg(lambda x: x.value_counts().index[0])
        .to_dict()
    )

    index_path = Path('data' / 'indices' / 'bm25')
    index = build_index(catalog, index_path)

    queries = list(ground_truth.keys())[:1000]
    grid_results = grid_search(index, ground_truth, queries)

    with open(output_dir / 'phase1_grid.json', 'w') as f:
        json.dump(grid_results, f, indent=2)

    print(f"Best config: {grid_results['best']}")
```

## Phase 2: e5-small ONNX Embeddings

```python
# src/embeddings.py
"""Phase 2: e5-small embeddings with ONNX Runtime INT8."""

import numpy as np
import onnxruntime as ort
from pathlib import Path
from typing import Optional
import pandas as pd


class EmbeddingModel:
    """e5-small multilingual embeddings via ONNX Runtime INT8."""

    def __init__(self, model_path: Path, providers: Optional[list] = None):
        """Load ONNX model with INT8 quantization."""
        sess_options = ort.SessionOptions()
        sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

        self.session = ort.InferenceSession(
            str(model_path),
            sess_options,
            providers=providers or ['CPUExecutionProvider'],
        )
        self.input_name = self.session.get_inputs()[0].name
        self.output_name = self.session.get_outputs()[0].name

    def encode(self, texts: list[str], batch_size: int = 32) -> np.ndarray:
        """Encode texts to embeddings. Returns (n, 384) float32 array."""
        embeddings = []

        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            prefixed = [f"query: {t}" for t in batch]

            outputs = self.session.run(
                [self.output_name],
                {self.input_name: prefixed}
            )
            embeddings.append(outputs[0])

        return np.vstack(embeddings).astype(np.float32)

    def encode_single(self, text: str) -> np.ndarray:
        """Encode single text."""
        return self.encode([text])[0]


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Compute cosine similarity between query and all document embeddings."""
    a_norm = a / np.linalg.norm(a, axis=1, keepdims=True)
    b_norm = b / np.linalg.norm(b, axis=1, keepdims=True)
    return np.dot(a_norm, b_norm.T)


def rerank_with_rrf(
    bm25_scores: dict[str, float],
    embedding_scores: dict[str, float],
    k: int = 60,
) -> list[tuple[str, float]]:
    """Reciprocal Rank Fusion combining BM25 and embedding scores."""
    scores = defaultdict(float)

    for rank, (doc_id, score) in enumerate(
        sorted(bm25_scores.items(), key=lambda x: x[1], reverse=True), 1
    ):
        scores[doc_id] += 1 / (k + rank)

    for rank, (doc_id, score) in enumerate(
        sorted(embedding_scores.items(), key=lambda x: x[1], reverse=True), 1
    ):
        scores[doc_id] += 1 / (k + rank)

    return sorted(scores.items(), key=lambda x: x[1], reverse=True)


class SearchPipeline:
    """End-to-end search pipeline with BM25 + embeddings."""

    def __init__(
        self,
        index,
        embedding_model: EmbeddingModel,
        doc_embeddings: np.ndarray,
        doc_ids: list[str],
        k1: float = 0.5,
        b: float = 0.0,
    ):
        self.index = index
        self.embedding_model = embedding_model
        self.doc_embeddings = doc_embeddings
        self.doc_ids = doc_ids
        self.k1 = k1
        self.b = b

    def search(
        self,
        query: str,
        top_k: int = 50,
        hybrid: bool = True,
    ) -> list[tuple[str, float, dict]]:
        """Search pipeline returning doc_id, score, and metadata."""
        import time

        t0 = time.perf_counter()
        results = []

        # BM25 retrieval (budget: 3ms)
        bm25_hits = self.index.search(query, top_k=100, k1=self.k1, b=self.b)
        bm25_scores = {doc_id: score for doc_id, score in bm25_hits}
        results = [(doc_id, score, {'source': 'bm25'}) for doc_id, score in bm25_hits]

        # Embedding encode (budget: 5ms)
        if hybrid:
            t1 = time.perf_counter()
            query_emb = self.embedding_model.encode_single(query)
            emb_time = (time.perf_counter() - t1) * 1000

            # Cosine similarity (budget: 1ms)
            t2 = time.perf_counter()
            similarities = cosine_similarity(
                query_emb.reshape(1, -1),
                self.doc_embeddings,
            )[0]
            sim_time = (time.perf_counter() - t2) * 1000

            # RRF merge (budget: 1ms)
            t3 = time.perf_counter()
            embedding_scores = {
                doc_id: similarities[i]
                for i, doc_id in enumerate(self.doc_ids)
            }
            fused = rerank_with_rrf(bm25_scores, embedding_scores, k=60)
            rrf_time = (time.perf_counter() - t3) * 1000

            results = [
                (doc_id, score, {'source': 'hybrid', 'emb_ms': emb_time, 'sim_ms': sim_time, 'rrf_ms': rrf_time})
                for doc_id, score in fused[:top_k]
            ]

        total_ms = (time.perf_counter() - t0) * 1000

        return results, {
            'total_ms': total_ms,
            'bm25_count': len(bm25_hits),
        }
```

## Phase 3: CatBoost YetiRank Training

```python
# src/ltr_train.py
"""Phase 3: CatBoost YetiRank training with IPW and walk-forward CV."""

import json
import numpy as np
import pandas as pd
from pathlib import Path
from catboost import CatBoostClassifier, Pool
from typing import Optional


FEATURE_SPEC = {
    'bm25_score': 'float',
    'embedding_similarity': 'float',
    'popularity': 'float',
    'recency_days': 'int',
    'has_bm25_match': 'int',
    'query_term_count': 'int',
    'title_match_count': 'int',
    'category_match': 'int',
    'price_bucket': 'int',
    'inventory_level': 'int',
}


def inverse_propensity_weight(position: int) -> float:
    """IPW: weight = 1 / log2(position + 1)."""
    return 1.0 / np.log2(position + 1)


def generate_training_data(
    clicks: pd.DataFrame,
    queries: pd.DataFrame,
    catalog: pd.DataFrame,
    features: pd.DataFrame,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Generate training data with IPW weights."""
    data = clicks.merge(features, on=['query', 'doc_id'])
    data = data.merge(queries[['query', 'query_term_count']], on='query')

    def compute_weights(group):
        group = group.sort_values('timestamp')
        group['position'] = range(1, len(group) + 1)
        group['ipw_weight'] = group['position'].apply(inverse_propensity_weight)
        return group

    data = data.groupby('query', group_keys=False).apply(compute_weights)

    def apply_skip_above(group):
        clicked_positions = set(group[group['clicked'] == 1]['position'])
        if not clicked_positions:
            return group
        min_clicked = min(clicked_positions)
        group['label'] = (
            (group['clicked'] == 1) &
            (group['position'] <= min_clicked + 2)
        ).astype(int)
        return group

    data = data.groupby('query', group_keys=False).apply(apply_skip_above)

    feature_cols = list(FEATURE_SPEC.keys())
    X = data[feature_cols].values
    y = data['label'].values
    weights = data['ipw_weight'].values

    return X, y, weights


def train_catboost_ltr(
    X_train: np.ndarray,
    y_train: np.ndarray,
    weights_train: np.ndarray,
    X_test: np.ndarray,
    y_test: np.ndarray,
    feature_names: list[str],
    params: Optional[dict] = None,
) -> CatBoostClassifier:
    """Train CatBoost with YetiRank loss."""
    default_params = {
        'loss_function': 'YetiRank',
        'iterations': 500,
        'depth': 6,
        'learning_rate': 0.05,
        'task_type': 'CPU',
        'verbose': 100,
        'early_stopping_rounds': 50,
    }
    if params:
        default_params.update(params)

    train_pool = Pool(
        X_train, y_train,
        weight=weights_train,
        feature_names=feature_names,
    )
    test_pool = Pool(
        X_test, y_test,
        feature_names=feature_names,
    )

    model = CatBoostClassifier(**default_params)
    model.fit(train_pool, eval_set=test_pool, use_best_model=True)

    return model


def walk_forward_cv(
    clicks: pd.DataFrame,
    queries: pd.DataFrame,
    catalog: pd.DataFrame,
    features: pd.DataFrame,
    n_splits: int = 5,
) -> list[dict]:
    """Walk-forward cross-validation respecting temporal structure."""
    clicks['timestamp'] = pd.to_datetime(clicks['timestamp'])
    clicks = clicks.sort_values('timestamp')

    results = []
    unique_weeks = sorted(clicks['timestamp'].dt.isocalendar().week.unique())

    for i in range(len(unique_weeks) - n_splits + 1, len(unique_weeks)):
        train_weeks = unique_weeks[i - n_splits:i]
        test_week = unique_weeks[i]

        train_mask = clicks['timestamp'].dt.isocalendar().week.isin(train_weeks)
        test_mask = clicks['timestamp'].dt.isocalendar().week == test_week

        X_train, y_train, w_train = generate_training_data(
            clicks[train_mask], queries, catalog, features
        )
        X_test, y_test, _ = generate_training_data(
            clicks[test_mask], queries, catalog, features
        )

        model = train_catboost_ltr(
            X_train, y_train, w_train,
            X_test, y_test,
            list(FEATURE_SPEC.keys()),
        )

        test_preds = model.predict(X_test)
        mrr = compute_mrr_at_k(test_preds, y_test, k=10)
        ndcg = compute_ndcg_at_k(test_preds, y_test, k=10)

        results.append({
            'train_weeks': list(train_weeks),
            'test_week': test_week,
            'mrr': mrr,
            'ndcg@10': ndcg,
        })

    return results


def main():
    data_dir = Path('data')
    output_dir = data_dir / 'models'
    output_dir.mkdir(parents=True, exist_ok=True)

    clicks = pd.read_parquet(data_dir / 'raw' / 'clicks.parquet')
    queries = pd.read_parquet(data_dir / 'raw' / 'queries.parquet')
    catalog = pd.read_parquet(data_dir / 'raw' / 'catalog.parquet')
    features = pd.read_parquet(data_dir / 'processed' / 'features.parquet')

    cv_results = walk_forward_cv(clicks, queries, catalog, features)

    X, y, weights = generate_training_data(clicks, queries, catalog, features)
    model = train_catboost_ltr(X, y, weights, X, y, list(FEATURE_SPEC.keys()))

    model.save_model(str(output_dir / 'model.cbm'))

    with open(output_dir / 'feature_spec.json', 'w') as f:
        json.dump(FEATURE_SPEC, f, indent=2)

    evaluation = {
        'cv_results': cv_results,
        'cv_mrr_mean': np.mean([r['mrr'] for r in cv_results]),
        'cv_mrr_std': np.std([r['mrr'] for r in cv_results]),
        'cv_ndcg_mean': np.mean([r['ndcg@10'] for r in cv_results]),
        'cv_ndcg_std': np.std([r['ndcg@10'] for r in cv_results]),
        'feature_importance': dict(zip(
            FEATURE_SPEC.keys(),
            model.get_feature_importance().tolist(),
        )),
    }

    with open(data_dir / 'evaluations' / 'phase3_ltr.json', 'w') as f:
        json.dump(evaluation, f, indent=2, default=str)

    print(f"Model saved to {output_dir / 'model.cbm'}")
    print(f"CV MRR: {evaluation['cv_mrr_mean']:.4f} ± {evaluation['cv_mrr_std']:.4f}")
```

## Phase 3: LTR Serving

```python
# src/ltr_serving.py
"""Phase 3: CatBoost LTR serving with feature computation."""

import json
import numpy as np
from pathlib import Path
from catboost import CatBoostClassifier
import pandas as pd
from typing import Optional


class FeatureComputer:
    """Compute LTR features at inference time."""

    def __init__(self, feature_spec_path: Path):
        with open(feature_spec_path) as f:
            self.spec = json.load(f)

    def compute(
        self,
        query: str,
        doc: dict,
        bm25_score: float,
        embedding_score: float,
        catalog_stats: dict,
    ) -> np.ndarray:
        """Compute feature vector for a (query, doc) pair."""
        features = {}

        features['bm25_score'] = bm25_score
        features['embedding_similarity'] = embedding_score
        features['popularity'] = doc.get('popularity', 0) / catalog_stats.get('max_popularity', 1)
        features['recency_days'] = (
            pd.Timestamp.now() - pd.to_datetime(doc.get('created_at'))
        ).days
        features['has_bm25_match'] = 1 if bm25_score > 0 else 0
        features['query_term_count'] = len(query.split())
        features['title_match_count'] = sum(
            1 for term in query.split() if term in doc.get('name', '').lower()
        )
        features['category_match'] = 1 if query.lower() in doc.get('category', '').lower() else 0
        features['price_bucket'] = self._price_bucket(doc.get('price', 0))
        features['inventory_level'] = self._inventory_bucket(doc.get('stock', 0))

        return np.array([features[k] for k in self.spec.keys()])


class LRTRanker:
    """Learning-to-rank inference pipeline."""

    def __init__(
        self,
        model_path: Path,
        feature_spec_path: Path,
        catalog_stats_path: Optional[Path] = None,
    ):
        self.model = CatBoostClassifier()
        self.model.load_model(str(model_path))
        self.feature_computer = FeatureComputer(feature_spec_path)

        if catalog_stats_path and catalog_stats_path.exists():
            with open(catalog_stats_path) as f:
                self.catalog_stats = json.load(f)
        else:
            self.catalog_stats = {'max_popularity': 1}

    def rank(
        self,
        query: str,
        candidates: list[dict],
        bm25_scores: list[float],
        embedding_scores: list[float],
        top_k: int = 50,
    ) -> list[tuple[dict, float]]:
        """Rank candidates using LTR model."""
        features = []
        for doc, bm25, emb in zip(candidates, bm25_scores, embedding_scores):
            feat_vec = self.feature_computer.compute(
                query, doc, bm25, emb, self.catalog_stats
            )
            features.append(feat_vec)

        X = np.vstack(features)
        scores = self.model.predict(X)

        ranked = sorted(
            zip(candidates, scores),
            key=lambda x: x[1],
            reverse=True,
        )

        return ranked[:top_k]


def main():
    model_path = Path('data/models/model.cbm')
    feature_spec_path = Path('data/models/feature_spec.json')

    ranker = LRTRanker(model_path, feature_spec_path)

    query = "cafe molido organico"
    candidates = [
        {'id': '1', 'name': 'Cafe Molido Organico 1kg', 'popularity': 100, 'price': 9.99},
        {'id': '2', 'name': 'Cafe Molido 500g', 'popularity': 50, 'price': 5.99},
    ]
    bm25_scores = [0.95, 0.82]
    embedding_scores = [0.88, 0.75]

    ranked = ranker.rank(query, candidates, bm25_scores, embedding_scores)
    print(f"Top result: {ranked[0][0]['id']} with score {ranked[0][1]:.3f}")
```

## CI/CD: Latency Benchmark

```python
# src/benchmark.py
"""C1: Latency benchmark for CI/CD pipeline."""

import json
import time
import numpy as np
from pathlib import Path
from typing import Callable
import pandas as pd


def benchmark_component(
    func: Callable,
    warmup: int = 10,
    iterations: int = 1000,
    percentile: float = 0.99,
) -> dict:
    """Benchmark a function with p50, p95, p99 latency."""
    for _ in range(warmup):
        func()

    latencies = []
    for _ in range(iterations):
        start = time.perf_counter()
        func()
        latencies.append((time.perf_counter() - start) * 1000)

    latencies = np.array(latencies)

    return {
        'p50': float(np.percentile(latencies, 50)),
        'p95': float(np.percentile(latencies, 95)),
        'p99': float(np.percentile(latencies, 99)),
        'mean': float(np.mean(latencies)),
        'std': float(np.std(latencies)),
    }


def benchmark_pipeline(pipeline, queries: list[str]) -> dict:
    """Benchmark full pipeline per component."""
    results = {
        'normalization': [],
        'bm25_retrieval': [],
        'embedding_encode': [],
        'cosine_similarity': [],
        'rrf_merge': [],
        'feature_computation': [],
        'ltr_predict': [],
        'serialization': [],
        'total': [],
    }

    for query in queries:
        t0 = time.perf_counter()

        t_norm = time.perf_counter()
        normalized = query.lower().strip()
        results['normalization'].append((time.perf_counter() - t_norm) * 1000)

        t_bm25 = time.perf_counter()
        bm25_hits = pipeline.index.search(normalized, top_k=100)
        results['bm25_retrieval'].append((time.perf_counter() - t_bm25) * 1000)

        t_emb = time.perf_counter()
        query_emb = pipeline.embedding_model.encode_single(normalized)
        results['embedding_encode'].append((time.perf_counter() - t_emb) * 1000)

        t_sim = time.perf_counter()
        similarities = cosine_similarity(query_emb.reshape(1, -1), pipeline.doc_embeddings)[0]
        results['cosine_similarity'].append((time.perf_counter() - t_sim) * 1000)

        t_rrf = time.perf_counter()
        fused = rerank_with_rrf(
            {doc_id: score for doc_id, score in bm25_hits},
            {doc_id: similarities[i] for i, doc_id in enumerate(pipeline.doc_ids)},
        )
        results['rrf_merge'].append((time.perf_counter() - t_rrf) * 1000)

        t_feat = time.perf_counter()
        candidates = [pipeline.catalog[pid] for pid, _ in fused[:60]]
        features = [pipeline.feature_computer.compute(query, doc, bm25, emb)
                    for doc, (pid, _), bm25, emb in zip(candidates, fused[:60], ...)]
        results['feature_computation'].append((time.perf_counter() - t_feat) * 1000)

        t_ltr = time.perf_counter()
        scores = pipeline.ltr_model.predict(np.vstack(features))
        results['ltr_predict'].append((time.perf_counter() - t_ltr) * 1000)

        t_ser = time.perf_counter()
        json.dumps([{'id': pid, 'score': float(s)} for pid, s in zip([p for p, _ in fused], scores)])
        results['serialization'].append((time.perf_counter() - t_ser) * 1000)

        results['total'].append((time.perf_counter() - t0) * 1000)

    budget = {
        'normalization': 0.5,
        'bm25_retrieval': 3.0,
        'embedding_encode': 5.0,
        'cosine_similarity': 1.0,
        'rrf_merge': 1.0,
        'feature_computation': 1.0,
        'ltr_predict': 1.0,
        'serialization': 0.5,
        'total': 15.0,
    }

    report = {}
    for component, latencies in results.items():
        arr = np.array(latencies)
        report[component] = {
            'p50': float(np.percentile(arr, 50)),
            'p99': float(np.percentile(arr, 99)),
            'budget': budget.get(component, None),
            'over_budget': np.percentile(arr, 99) > budget.get(component, float('inf')),
        }

    return report


def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path('data/evaluations/benchmark.json'))
    args = parser.parse_args()

    from src.ltr_serving import LRTRanker
    ranker = LRTRanker(
        Path('data/models/model.cbm'),
        Path('data/models/feature_spec.json'),
    )

    queries = pd.read_parquet('data/raw/queries.parquet')['query'].unique()[:1000].tolist()

    report = benchmark_pipeline(ranker, queries)

    failures = []
    for component, stats in report.items():
        if stats.get('over_budget'):
            failures.append(f"{component}: p99={stats['p99']:.2f}ms > budget={stats['budget']}ms")

    if failures:
        print("BENCHMARK FAILURES:")
        for f in failures:
            print(f"  - {f}")
        exit(1)

    with open(args.output, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"Benchmark saved to {args.output}")
```

## Structured Logging

```python
# src/logging.py
"""Structured JSON logging for search pipeline."""

import logging
import json
import sys
from datetime import datetime, timezone
from typing import Optional, Any


class StructuredLogger:
    """JSON structured logger for search services."""

    def __init__(self, component: str):
        self.component = component
        self.logger = logging.getLogger(component)
        self.logger.setLevel(logging.INFO)

        if not self.logger.handlers:
            handler = logging.StreamHandler(sys.stdout)
            handler.setFormatter(logging.Formatter('%(message)s'))
            self.logger.addHandler(handler)

    def log(
        self,
        level: str,
        message: str,
        query: Optional[str] = None,
        latency_ms: Optional[float] = None,
        results_count: Optional[int] = None,
        error: Optional[str] = None,
        **extra: Any,
    ):
        """Log a structured JSON message."""
        log_entry = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'level': level,
            'component': self.component,
            'message': message,
        }

        if query is not None:
            log_entry['query'] = query
        if latency_ms is not None:
            log_entry['latency_ms'] = round(latency_ms, 3)
        if results_count is not None:
            log_entry['results_count'] = results_count
        if error is not None:
            log_entry['error'] = error
        log_entry.update(extra)

        getattr(self.logger, level.lower())(json.dumps(log_entry))


# Usage
logger = StructuredLogger('bm25_retriever')

def search_with_logging(index, query: str, top_k: int = 50):
    import time
    t0 = time.perf_counter()

    results = index.search(query, top_k=top_k)

    logger.log(
        'INFO',
        'Search completed',
        query=query,
        latency_ms=(time.perf_counter() - t0) * 1000,
        results_count=len(results),
    )

    return results
```

## ML Metrics

```python
# src/metrics.py
"""ML metrics for search quality evaluation."""

import numpy as np
from typing import Optional


def mean_reciprocal_rank(
    predictions: list[list[str]],
    ground_truth: list[set[str]],
    k: int = 10,
) -> float:
    """MRR@k: Mean of 1/rank of first relevant result."""
    rr_scores = []

    for preds, relevant in zip(predictions, ground_truth):
        for rank, doc_id in enumerate(preds[:k], 1):
            if doc_id in relevant:
                rr_scores.append(1.0 / rank)
                break
        else:
            rr_scores.append(0.0)

    return np.mean(rr_scores) if rr_scores else 0.0


def ndcg_at_k(
    predictions: list[list[str]],
    ground_truth: list[list[tuple[str, int]]],
    k: int = 10,
) -> float:
    """NDCG@k: Normalized Discounted Cumulative Gain."""
    def dcg(relevance: list[int], k: int = k) -> float:
        return sum((2**r - 1) / np.log2(i + 2) for i, r in enumerate(relevance[:k]))

    dcg_scores = []

    for preds, relevant in zip(predictions, ground_truth):
        relevance_map = dict(relevant)
        relevance = [relevance_map.get(doc_id, 0) for doc_id in preds[:k]]

        dcg_score = dcg(relevance)
        ideal_relevance = sorted([r for _, r in relevant], reverse=True)[:k]
        idcg = dcg(ideal_relevance)

        dcg_scores.append(dcg_score / idcg if idcg > 0 else 0.0)

    return np.mean(dcg_scores) if dcg_scores else 0.0


def recall_at_k(
    predictions: list[list[str]],
    ground_truth: list[set[str]],
    k: int = 50,
) -> float:
    """Recall@k: Fraction of relevant docs in top-k."""
    recall_scores = []

    for preds, relevant in zip(predictions, ground_truth):
        relevant_set = set(relevant)
        if not relevant_set:
            continue
        predicted_set = set(preds[:k])
        recall_scores.append(len(predicted_set & relevant_set) / len(relevant_set))

    return np.mean(recall_scores) if recall_scores else 0.0


def no_results_rate(queries_with_results: list[bool]) -> float:
    """Percentage of queries returning zero results."""
    return sum(1 for has_results in queries_with_results if not has_results) / len(queries_with_results)


def ctr_top_k(clicks: list[tuple[str, int]], k: int = 3) -> float:
    """CTR@k: Click-through rate on top-k positions."""
    if not clicks:
        return 0.0
    clicks_top_k = sum(1 for doc_id, pos in clicks if pos <= k)
    return clicks_top_k / len(clicks)


def deep_scroll_rate(clicks: list[tuple[str, int]], threshold: int = 21) -> float:
    """Rate of clicks beyond a certain position."""
    if not clicks:
        return 0.0
    deep_clicks = sum(1 for doc_id, pos in clicks if pos >= threshold)
    return deep_clicks / len(clicks)
```