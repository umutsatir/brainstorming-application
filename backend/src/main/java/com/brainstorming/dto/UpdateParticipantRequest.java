package com.brainstorming.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateParticipantRequest {
    
    private String fullName;
    private String phone;
    private String role; // EVENT_MANAGER, TEAM_LEADER, TEAM_MEMBER
    private String status; // ACTIVE, INACTIVE, INVITED
}
