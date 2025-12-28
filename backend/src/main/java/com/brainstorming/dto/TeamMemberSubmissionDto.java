package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamMemberSubmissionDto {
    private Long userId;
    private String userName;
    private Boolean submitted;
    private LocalDateTime submittedAt;
}
