package com.brainstorming.repository;

import com.brainstorming.entity.EventParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EventParticipantRepository extends JpaRepository<EventParticipant, Long> {
    
    List<EventParticipant> findByEventId(Long eventId);
    
    List<EventParticipant> findByUserId(Long userId);
    
    Optional<EventParticipant> findByEventIdAndUserId(Long eventId, Long userId);
    
    boolean existsByEventIdAndUserId(Long eventId, Long userId);
}
