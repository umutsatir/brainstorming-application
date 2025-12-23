package com.brainstorming.repository;

import com.brainstorming.entity.RealtimeToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RealtimeTokenRepository extends JpaRepository<RealtimeToken, Long> {
    
    List<RealtimeToken> findByUserId(Long userId);
    
    Optional<RealtimeToken> findByToken(String token);
}
