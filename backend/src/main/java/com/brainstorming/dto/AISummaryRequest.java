package com.brainstorming.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AISummaryRequest {
    
    private String style;
    
    private String length;
    
    private String language;
}

