package com.brainstorming.dto;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AISummaryResponse {
    
    private Long summaryId;
    
    private String summaryText;
    
    private List<String> keyThemes;
    
    private List<String> notableIdeas;
}

