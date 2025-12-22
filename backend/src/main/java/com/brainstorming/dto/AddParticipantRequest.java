package com.brainstorming.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AddParticipantRequest {
    
    @NotNull(message = "Event ID is required")
    private Long eventId;
    
    @NotNull(message = "User ID is required")
    private Long userId;
    
    private String roleOverride; // EVENT_MANAGER, TEAM_LEADER, TEAM_MEMBER
}
