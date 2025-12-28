package com.brainstorming.repository;

import com.brainstorming.entity.Idea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IdeaRepository extends JpaRepository<Idea, Long> {
    
    List<Idea> findBySessionId(Long sessionId);
    
    List<Idea> findByRoundId(Long roundId);
    
    List<Idea> findByAuthorId(Long authorId);
    
    List<Idea> findByTeamId(Long teamId);
    
    List<Idea> findBySessionIdAndRoundId(Long sessionId, Long roundId);
    
    List<Idea> findByRoundIdAndAuthorId(Long roundId, Long authorId);
    
    boolean existsByRoundIdAndAuthorId(Long roundId, Long authorId);
}
