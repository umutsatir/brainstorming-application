package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionStateDto {
    private SessionDto session;
    private RoundDto currentRound;
    private Integer timerRemainingSeconds;
    private List<IdeaDto> previousIdeas;
    private List<IdeaDto> myIdeas;
    private List<TeamMemberSubmissionDto> teamSubmissions;
    private Boolean canSubmit;
    private Boolean isRoundLocked;
    private String userRole;
}
