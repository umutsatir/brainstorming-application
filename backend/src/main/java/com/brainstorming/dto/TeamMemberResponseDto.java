package com.brainstorming.dto;

import com.brainstorming.entity.User;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamMemberResponseDto {
    private Long id;
    private String fullName;
    private String email;
    private String role;  // "TEAM_LEADER" or "TEAM_MEMBER" based on team context
    private User.Status status;
    private boolean isTeamLeader;
}
