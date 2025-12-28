package com.brainstorming.dto;

import lombok.*;

import java.util.Map;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdvanceRoundResponseDto {
    private Integer currentRound;
    private String previousRoundStatus;
    private Map<Long, List<IdeaDto>> passedIdeaMap; // userId -> ideas passed to them
}
