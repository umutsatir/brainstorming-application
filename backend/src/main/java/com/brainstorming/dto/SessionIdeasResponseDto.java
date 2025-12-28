package com.brainstorming.dto;

import lombok.*;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionIdeasResponseDto {
    private Long sessionId;
    private Integer totalRounds;
    private Integer totalIdeas;
    private Map<Integer, List<RoundParticipantIdeasDto>> ideasByRound; // roundNumber -> list of participant ideas
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class RoundParticipantIdeasDto {
        private Long participantId;
        private String participantName;
        private List<IdeaDto> ideas;
    }
}
