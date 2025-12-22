package com.brainstorming.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateIdeaRequest {
    
    @NotNull(message = "Session ID is required")
    private Long sessionId;
    
    @NotNull(message = "Round ID is required")
    private Long roundId;
    
    @NotBlank(message = "Idea text is required")
    private String text;
    
    private Long passedFromUserId;
}
