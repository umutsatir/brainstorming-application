package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionReportDto {
    private Long sessionId;
    private String topicTitle;
    private String topicDescription;
    private String teamName;
    private String status;
    private Integer currentRound;
    private Integer roundCount;
    private Integer totalIdeas;
    private List<RoundReportDto> rounds;
    private LocalDateTime createdAt;
}
