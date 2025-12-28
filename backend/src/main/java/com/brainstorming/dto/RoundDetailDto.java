package com.brainstorming.dto;

import com.brainstorming.entity.Round;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoundDetailDto {
    private Long id;
    private Long sessionId;
    private Integer roundNumber;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Round.TimerState timerState;
    private Integer timerRemainingSeconds;
    private List<MemberSubmissionStatusDto> memberSubmissions;
    private Integer submittedCount;
    private Integer totalMembers;
    private LocalDateTime createdAt;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MemberSubmissionStatusDto {
        private Long userId;
        private String userName;
        private Boolean hasSubmitted;
        private LocalDateTime submittedAt;
    }
}
