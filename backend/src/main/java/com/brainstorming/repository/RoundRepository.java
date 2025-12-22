package com.brainstorming.repository;

import com.brainstorming.entity.Round;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoundRepository extends JpaRepository<Round, Long> {
    
    List<Round> findBySessionId(Long sessionId);
    
    Optional<Round> findBySessionIdAndRoundNumber(Long sessionId, Integer roundNumber);
}
