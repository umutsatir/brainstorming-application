package com.brainstorming.dto;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AISuggestionResponse {
    
    private List<Suggestion> suggestions;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Suggestion {
        private Long id;
        private String text;
    }
}

