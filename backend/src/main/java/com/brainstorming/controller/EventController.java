package com.brainstorming.controller;

import com.brainstorming.dto.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
public class EventController {

    // TODO: Inject EventService
    
    @GetMapping
    public ResponseEntity<List<EventDto>> getAllEvents() {
        // TODO: Implement get all events
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<EventDto> getEventById(@PathVariable Long id) {
        // TODO: Implement get event by id
        return ResponseEntity.ok().build();
    }
    
    @PostMapping
    public ResponseEntity<EventDto> createEvent(@RequestBody CreateEventRequest request) {
        // TODO: Implement create event
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<EventDto> updateEvent(@PathVariable Long id, @RequestBody CreateEventRequest request) {
        // TODO: Implement update event
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvent(@PathVariable Long id) {
        // TODO: Implement delete event
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{eventId}/teams")
    public ResponseEntity<List<TeamDto>> getEventTeams(@PathVariable Long eventId) {
        // TODO: Implement get teams for event
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{eventId}/topics")
    public ResponseEntity<List<TopicDto>> getEventTopics(@PathVariable Long eventId) {
        // TODO: Implement get topics for event
        return ResponseEntity.ok().build();
    }
}
