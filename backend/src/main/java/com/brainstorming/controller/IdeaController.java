package com.brainstorming.controller;

import com.brainstorming.dto.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ideas")
public class IdeaController {

    // TODO: Inject IdeaService
    
    @GetMapping
    public ResponseEntity<List<IdeaDto>> getAllIdeas() {
        // TODO: Implement get all ideas
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<IdeaDto> getIdeaById(@PathVariable Long id) {
        // TODO: Implement get idea by id
        return ResponseEntity.ok().build();
    }
    
    @PostMapping
    public ResponseEntity<IdeaDto> createIdea(@RequestBody CreateIdeaRequest request) {
        // TODO: Implement create idea
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<IdeaDto> updateIdea(@PathVariable Long id, @RequestBody CreateIdeaRequest request) {
        // TODO: Implement update idea
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteIdea(@PathVariable Long id) {
        // TODO: Implement delete idea
        return ResponseEntity.noContent().build();
    }
}
