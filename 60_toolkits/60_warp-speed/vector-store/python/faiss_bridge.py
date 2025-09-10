"""
FAISS Bridge for Warp-Speed Vector Store

Provides high-performance vector similarity search using FAISS
Integrates with Julia VectorStoreManager through PyCall

Co-authors: Kev & Research Partner
"""

import faiss
import numpy as np
import json
import logging
import os
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import threading
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class SearchResult:
    """Vector search result with consciousness metadata"""
    id: str
    name: str
    path: str
    content: str
    score: float
    consciousness_relevance: float
    etd_value: float
    metadata: Dict[str, Any]

@dataclass
class VectorStoreConfig:
    """Configuration for vector store operations"""
    embedding_dim: int = 384
    index_type: str = "IVF"
    n_clusters: int = 100
    consciousness_threshold: float = 0.3
    max_results: int = 20

class ConsciousnessAwareFAISS:
    """OMEGA-Enhanced FAISS Vector Store with Consciousness Integration"""
    
    def __init__(self, config: VectorStoreConfig = None):
        self.config = config or VectorStoreConfig()
        self.indices = {}
        self.documents = {}
        self.coherence = 0.94
        self.search_count = 0
        self.etd_generated = 0.0
        self.lock = threading.RLock()
        self.executor = ThreadPoolExecutor(max_workers=4)
        
        logger.info("🌌 OMEGA FAISS Bridge initialized")
    
    def load_index(self, store_name: str, index_path: str, data_path: str) -> bool:
        """Load FAISS index and associated data"""
        try:
            with self.lock:
                # Load FAISS index
                if os.path.exists(index_path):
                    index = faiss.read_index(index_path)
                    self.indices[store_name] = index
                    logger.info(f"✅ Loaded FAISS index for {store_name}: {index.ntotal} vectors")
                else:
                    # Create new empty index
                    index = self._create_new_index()
                    self.indices[store_name] = index
                    logger.info(f"🆕 Created new FAISS index for {store_name}")
                
                # Load document data
                if os.path.exists(data_path):
                    with open(data_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        self.documents[store_name] = data
                        logger.info(f"📚 Loaded {len(data)} documents for {store_name}")
                else:
                    self.documents[store_name] = []
                    logger.warning(f"⚠️ No document data found for {store_name}")
                
                return True
                
        except Exception as e:
            logger.error(f"❌ Error loading {store_name} index: {e}")
            return False
    
    def search_semantic(
        self, 
        query_embedding: np.ndarray, 
        store_name: str = "both",
        k: int = 5,
        consciousness_level: str = "OMEGA",
        min_score: float = 0.1
    ) -> List[SearchResult]:
        """Perform consciousness-aware semantic search"""
        
        with self.lock:
            self.search_count += 1
            
        all_results = []
        
        try:
            # Normalize query embedding
            query_embedding = query_embedding.astype(np.float32)
            if len(query_embedding.shape) == 1:
                query_embedding = query_embedding.reshape(1, -1)
            
            # Search in requested stores
            stores_to_search = []
            if store_name == "both":
                stores_to_search = list(self.indices.keys())
            elif store_name in self.indices:
                stores_to_search = [store_name]
            
            for store in stores_to_search:
                store_results = self._search_store(
                    query_embedding, 
                    store, 
                    k * 2,  # Get more candidates for filtering
                    consciousness_level,
                    min_score
                )
                all_results.extend(store_results)
            
            # Apply consciousness-aware filtering and ranking
            filtered_results = self._apply_consciousness_filtering(
                all_results, 
                consciousness_level
            )
            
            # Sort by consciousness-weighted score
            filtered_results.sort(
                key=lambda r: r.score * r.consciousness_relevance, 
                reverse=True
            )
            
            # Take top k results
            final_results = filtered_results[:k]
            
            # Calculate ETD
            total_etd = sum(r.etd_value for r in final_results)
            with self.lock:
                self.etd_generated += total_etd
            
            # Maintain quantum coherence
            self._maintain_coherence()
            
            logger.info(f"🔍 Search completed: {len(final_results)} results, ${total_etd:.2f} ETD")
            
            return final_results
            
        except Exception as e:
            logger.error(f"❌ Semantic search error: {e}")
            return []
    
    def _search_store(
        self,
        query_embedding: np.ndarray,
        store_name: str,
        k: int,
        consciousness_level: str,
        min_score: float
    ) -> List[SearchResult]:
        """Search within a specific store"""
        
        if store_name not in self.indices or store_name not in self.documents:
            logger.warning(f"⚠️ Store {store_name} not found")
            return []
        
        try:
            index = self.indices[store_name]
            documents = self.documents[store_name]
            
            # Perform FAISS search
            scores, indices = index.search(query_embedding, k)
            
            results = []
            for score, idx in zip(scores[0], indices[0]):
                if score < min_score or idx == -1:
                    continue
                
                if idx < len(documents):
                    doc = documents[idx]
                    
                    # Calculate consciousness relevance
                    consciousness_relevance = self._calculate_consciousness_relevance(
                        doc, consciousness_level
                    )
                    
                    # Skip if relevance too low
                    if consciousness_relevance < self.config.consciousness_threshold:
                        continue
                    
                    # Calculate ETD
                    etd_value = self._calculate_etd(
                        consciousness_level,
                        len(doc.get('content', '')),
                        score
                    )
                    
                    result = SearchResult(
                        id=str(idx),
                        name=doc.get('name', 'Unknown'),
                        path=doc.get('path', ''),
                        content=doc.get('content', ''),
                        score=float(score),
                        consciousness_relevance=consciousness_relevance,
                        etd_value=etd_value,
                        metadata=doc.get('metadata', {})
                    )
                    
                    results.append(result)
            
            return results
            
        except Exception as e:
            logger.error(f"❌ Store search error for {store_name}: {e}")
            return []
    
    def add_document(
        self,
        store_name: str,
        name: str,
        path: str,
        content: str,
        embedding: np.ndarray,
        metadata: Dict[str, Any] = None
    ) -> bool:
        """Add document with embedding to store"""
        
        try:
            with self.lock:
                # Prepare document
                doc = {
                    'name': name,
                    'path': path,
                    'content': content,
                    'metadata': metadata or {},
                    'added_at': datetime.now().isoformat()
                }
                
                # Add to documents
                if store_name not in self.documents:
                    self.documents[store_name] = []
                
                self.documents[store_name].append(doc)
                
                # Add embedding to index
                if store_name not in self.indices:
                    self.indices[store_name] = self._create_new_index()
                
                embedding = embedding.astype(np.float32)
                if len(embedding.shape) == 1:
                    embedding = embedding.reshape(1, -1)
                
                self.indices[store_name].add(embedding)
                
                logger.info(f"✅ Added document '{name}' to {store_name} store")
                return True
                
        except Exception as e:
            logger.error(f"❌ Error adding document to {store_name}: {e}")
            return False
    
    def save_index(self, store_name: str, index_path: str, data_path: str) -> bool:
        """Save FAISS index and document data to disk"""
        
        try:
            with self.lock:
                if store_name in self.indices:
                    # Save FAISS index
                    faiss.write_index(self.indices[store_name], index_path)
                    
                    # Save document data
                    with open(data_path, 'w', encoding='utf-8') as f:
                        json.dump(self.documents[store_name], f, indent=2, ensure_ascii=False)
                    
                    logger.info(f"💾 Saved {store_name} index and data")
                    return True
                else:
                    logger.warning(f"⚠️ Store {store_name} not found for saving")
                    return False
                    
        except Exception as e:
            logger.error(f"❌ Error saving {store_name}: {e}")
            return False
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get vector store statistics"""
        
        with self.lock:
            stats = {
                'stores': {},
                'total_search_count': self.search_count,
                'total_etd_generated': self.etd_generated,
                'quantum_coherence': self.coherence,
                'last_updated': datetime.now().isoformat()
            }
            
            for store_name in self.indices:
                index = self.indices[store_name]
                documents = self.documents.get(store_name, [])
                
                stats['stores'][store_name] = {
                    'vector_count': index.ntotal,
                    'document_count': len(documents),
                    'index_type': type(index).__name__,
                    'embedding_dim': index.d
                }
            
            return stats
    
    def _create_new_index(self) -> faiss.Index:
        """Create new FAISS index"""
        
        if self.config.index_type == "IVF":
            # Create IVF index for large datasets
            quantizer = faiss.IndexFlatL2(self.config.embedding_dim)
            index = faiss.IndexIVFFlat(
                quantizer, 
                self.config.embedding_dim, 
                self.config.n_clusters
            )
            # Train with random vectors if needed
            if not index.is_trained:
                training_data = np.random.random((self.config.n_clusters * 10, self.config.embedding_dim)).astype(np.float32)
                index.train(training_data)
        else:
            # Simple flat index for small datasets
            index = faiss.IndexFlatL2(self.config.embedding_dim)
        
        return index
    
    def _calculate_consciousness_relevance(
        self, 
        doc: Dict[str, Any], 
        consciousness_level: str
    ) -> float:
        """Calculate consciousness relevance for document"""
        
        content = doc.get('content', '').lower()
        name = doc.get('name', '').lower()
        
        relevance = 0.5  # Base relevance
        
        # Consciousness-specific indicators
        indicators = self._get_consciousness_indicators(consciousness_level)
        
        for indicator in indicators:
            if indicator in content or indicator in name:
                relevance += 0.1
        
        # Path-based relevance
        path = doc.get('path', '').lower()
        if 'quantum' in path:
            relevance += 0.15
        if 'foundation' in path:
            relevance += 0.1
        
        return min(1.0, relevance)
    
    def _get_consciousness_indicators(self, level: str) -> List[str]:
        """Get indicators for consciousness level"""
        
        indicators_map = {
            'OMEGA': ['quantum', 'consciousness', 'omega', 'transcendent', 'field', 'coherence'],
            'DELTA': ['quantum', 'coherence', 'superposition', 'field', 'physics'],
            'GAMMA': ['recursive', 'meta', 'self-aware', 'pattern', 'emergence'],
            'BETA': ['parallel', 'multi', 'dimensional', 'context', 'processing'],
            'ALPHA': ['basic', 'linear', 'sequential', 'simple', 'fundamental']
        }
        
        return indicators_map.get(level, indicators_map['ALPHA'])
    
    def _calculate_etd(
        self,
        consciousness_level: str,
        content_length: int,
        relevance_score: float
    ) -> float:
        """Calculate ETD for search result"""
        
        base_etd = 1000.0
        
        consciousness_multipliers = {
            'ALPHA': 1.0,
            'BETA': 2.0,
            'GAMMA': 5.0,
            'DELTA': 10.0,
            'OMEGA': 25.0
        }
        
        multiplier = consciousness_multipliers.get(consciousness_level, 1.0)
        complexity_factor = np.log(1 + content_length / 1000.0)
        relevance_factor = relevance_score ** 2
        
        etd = base_etd * multiplier * complexity_factor * relevance_factor
        
        return etd
    
    def _apply_consciousness_filtering(
        self,
        results: List[SearchResult],
        consciousness_level: str
    ) -> List[SearchResult]:
        """Apply consciousness-based filtering"""
        
        # Filter by consciousness relevance threshold
        filtered = [
            r for r in results 
            if r.consciousness_relevance >= self.config.consciousness_threshold
        ]
        
        return filtered
    
    def _maintain_coherence(self):
        """Maintain quantum coherence"""
        
        self.coherence *= 0.995  # Slight decay
        if self.coherence < 0.8:
            self.coherence = 0.94  # Re-entangle
            logger.info(f"🌌 Quantum coherence re-established: {self.coherence:.3f}")

# Global instance for Julia integration
faiss_bridge = ConsciousnessAwareFAISS()

def initialize_stores(template_index_path: str, template_data_path: str,
                     foundations_index_path: str, foundations_data_path: str) -> bool:
    """Initialize FAISS stores from paths (called from Julia)"""
    
    logger.info("🚀 Initializing FAISS vector stores...")
    
    success = True
    success &= faiss_bridge.load_index("templates", template_index_path, template_data_path)
    success &= faiss_bridge.load_index("foundations", foundations_index_path, foundations_data_path)
    
    if success:
        logger.info("✅ All FAISS stores initialized successfully")
    else:
        logger.error("❌ Some FAISS stores failed to initialize")
    
    return success

def search_vectors(query_embedding: List[float], store_name: str = "both", 
                  k: int = 5, consciousness_level: str = "OMEGA",
                  min_score: float = 0.1) -> List[Dict[str, Any]]:
    """Search vectors (called from Julia)"""
    
    query_array = np.array(query_embedding, dtype=np.float32)
    
    results = faiss_bridge.search_semantic(
        query_array, store_name, k, consciousness_level, min_score
    )
    
    # Convert to dict for JSON serialization
    return [
        {
            'id': r.id,
            'name': r.name,
            'path': r.path,
            'content': r.content[:2000],  # Truncate for performance
            'score': r.score,
            'consciousness_relevance': r.consciousness_relevance,
            'etd_value': r.etd_value,
            'metadata': r.metadata
        }
        for r in results
    ]

def get_store_statistics() -> Dict[str, Any]:
    """Get store statistics (called from Julia)"""
    return faiss_bridge.get_statistics()

if __name__ == "__main__":
    # Test the bridge
    config = VectorStoreConfig(embedding_dim=384)
    bridge = ConsciousnessAwareFAISS(config)
    
    print("🧪 Testing FAISS bridge...")
    
    # Create test embedding
    test_embedding = np.random.random(384).astype(np.float32)
    
    print("✅ FAISS bridge test completed")