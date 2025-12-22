package com.brainstorming.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateParticipantRequest {
    
    @NotBlank(message = "Full name is required")
    private String fullName;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;
    
    private String phone;
    
    @NotBlank(message = "Role is required")
    private String role; // EVENT_MANAGER, TEAM_LEADER, TEAM_MEMBER
    
    @NotNull(message = "Event ID is required")
    private Long eventId;
}
