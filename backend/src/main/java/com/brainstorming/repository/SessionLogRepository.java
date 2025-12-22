package com.brainstorming.repository;

import com.brainstorming.entity.SessionLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SessionLogRepository extends JpaRepository<SessionLog, Long> {
    
    List<SessionLog> findBySessionId(Long sessionId);
    
    List<SessionLog> findByUserId(Long userId);
    
    List<SessionLog> findBySessionIdOrderByCreatedAtDesc(Long sessionId);
}
