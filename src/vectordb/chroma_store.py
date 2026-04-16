import uuid
from pathlib import Path

import chromadb

from src.config import settings
from src.embeddings.encoder import encode, encode_one
from src.logger import get_logger

logger = get_logger(__name__)


class ChromaStore:
    def __init__(self):
        Path(settings.chroma_persist_dir).mkdir(parents=True, exist_ok=True)
        self._client = chromadb.PersistentClient(path=settings.chroma_persist_dir)
        self._collection = self._client.get_or_create_collection(
            name=settings.chroma_collection,
            metadata={"hnsw:space": "cosine"},
        )
        logger.info(
            f"ChromaDB listo: colección '{settings.chroma_collection}' "
            f"({self._collection.count()} vectores)"
        )

    def add_chunks(self, chunks: list) -> None:
        """Embed and upsert chunks into the collection.

        Each chunk must have: text, chunk_index, source_file.
        """
        if not chunks:
            return

        texts = [c["text"] for c in chunks]
        embeddings = encode(texts)

        ids = [str(uuid.uuid4()) for _ in chunks]
        metadatas = [
            {
                "source_file": c.get("source_file", "unknown"),
                "chunk_index": c.get("chunk_index", 0),
                **({"file_mtime": c["file_mtime"]} if "file_mtime" in c else {}),
            }
            for c in chunks
        ]

        self._collection.upsert(
            ids=ids,
            embeddings=embeddings,
            documents=texts,
            metadatas=metadatas,
        )
        logger.debug(f"Upsert: {len(chunks)} chunks añadidos/actualizados")

    def get_source_mtime(self, source_file: str) -> str | None:
        """Return the stored file_mtime for a source file, or None if not indexed."""
        try:
            result = self._collection.get(
                where={"source_file": source_file},
                limit=1,
                include=["metadatas"],
            )
            metas = result.get("metadatas") or []
            if metas:
                return metas[0].get("file_mtime")
        except Exception:
            pass
        return None

    def delete_by_source(self, source_file: str) -> int:
        """Delete all chunks belonging to a specific source file."""
        result = self._collection.get(
            where={"source_file": source_file},
        )
        ids = result.get("ids", [])
        if ids:
            self._collection.delete(ids=ids)
            logger.debug(f"Eliminados {len(ids)} chunks de '{source_file}'")
        return len(ids)

    def query(self, question: str, top_k: int = None) -> list:
        """Semantic search. Returns list of dicts with text, score, source_file, chunk_index."""
        k = top_k or settings.top_k
        count = self._collection.count()
        if count == 0:
            return []

        vector = encode_one(question)

        results = self._collection.query(
            query_embeddings=[vector],
            n_results=min(k, count),
            include=["documents", "metadatas", "distances"],
        )

        hits = []
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0],
        ):
            # ChromaDB cosine distance: 0 = identical, 2 = opposite
            # Convert to similarity score [0, 1]: score = 1 - dist/2
            score = round(1.0 - dist / 2.0, 4)
            hits.append(
                {
                    "text": doc,
                    "score": score,
                    "source_file": meta.get("source_file", "unknown"),
                    "chunk_index": meta.get("chunk_index", 0),
                }
            )

        return hits

    def count(self) -> int:
        return self._collection.count()

    def reset(self) -> None:
        """Delete the entire collection and recreate it (full reindex trigger)."""
        self._client.delete_collection(settings.chroma_collection)
        self._collection = self._client.get_or_create_collection(
            name=settings.chroma_collection,
            metadata={"hnsw:space": "cosine"},
        )
        logger.warning("ChromaDB: colección eliminada y recreada (reindex completo)")


# Module-level singleton used by pipeline and API
chroma_store = ChromaStore()
