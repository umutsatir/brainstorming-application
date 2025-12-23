package com.brainstorming.repository;

import com.brainstorming.entity.Topic;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TopicRepository extends JpaRepository<Topic, Long> {
    
    List<Topic> findByEventId(Long eventId);
    
    List<Topic> findByEventIdAndStatus(Long eventId, Topic.Status status);
}
