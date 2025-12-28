package com.brainstorming.dto;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoundIdeasResponseDto {
    private Integer roundNumber;
    private List<IdeaDto> previousTeammateIdeas;
    private List<IdeaDto> yourIdeas;
    private SubmissionStatusDto submissionStatus;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SubmissionStatusDto {
        private Integer submittedCount;
        private Integer totalMembers;
    }
}
