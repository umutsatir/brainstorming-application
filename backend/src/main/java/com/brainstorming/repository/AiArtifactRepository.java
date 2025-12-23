package com.brainstorming.repository;

import com.brainstorming.entity.AiArtifact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AiArtifactRepository extends JpaRepository<AiArtifact, Long> {
    
    List<AiArtifact> findBySessionId(Long sessionId);
    
    List<AiArtifact> findByRoundId(Long roundId);
    
    List<AiArtifact> findBySessionIdAndType(Long sessionId, AiArtifact.Type type);
}
