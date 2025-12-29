package com.brainstorming.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AISuggestionRequest {
    
    private Integer roundNumber;
    
    private String promptOverride;
}

