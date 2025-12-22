package com.brainstorming.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateSessionRequest {
    
    @NotNull(message = "Team ID is required")
    private Long teamId;
    
    @NotNull(message = "Topic ID is required")
    private Long topicId;
    
    @Builder.Default
    private Integer roundCount = 5;
}
