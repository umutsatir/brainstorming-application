package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoundReportDto {
    private Integer roundNumber;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String timerState;
    private Integer ideaCount;
    private List<IdeaDto> ideas;
}
