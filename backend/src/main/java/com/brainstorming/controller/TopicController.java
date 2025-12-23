package com.brainstorming.controller;

import com.brainstorming.dto.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/topics")
public class TopicController {

    // TODO: Inject TopicService
    
    @GetMapping
    public ResponseEntity<List<TopicDto>> getAllTopics() {
        // TODO: Implement get all topics
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<TopicDto> getTopicById(@PathVariable Long id) {
        // TODO: Implement get topic by id
        return ResponseEntity.ok().build();
    }
    
    @PostMapping
    public ResponseEntity<TopicDto> createTopic(@RequestBody CreateTopicRequest request) {
        // TODO: Implement create topic
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<TopicDto> updateTopic(@PathVariable Long id, @RequestBody CreateTopicRequest request) {
        // TODO: Implement update topic
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTopic(@PathVariable Long id) {
        // TODO: Implement delete topic
        return ResponseEntity.noContent().build();
    }
}
