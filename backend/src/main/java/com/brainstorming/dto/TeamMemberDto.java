package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamMemberDto {
    private Long id;
    private Long teamId;
    private Long userId;
    private String userName;
    private String userEmail;
    private LocalDateTime createdAt;
}
