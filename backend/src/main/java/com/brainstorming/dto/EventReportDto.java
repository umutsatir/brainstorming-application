package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventReportDto {
    private Long eventId;
    private String eventName;
    private String eventDescription;
    private LocalDate startDate;
    private LocalDate endDate;
    private String ownerName;
    private Integer totalTeams;
    private Integer totalTopics;
    private Integer totalSessions;
    private Integer totalIdeas;
    private Integer totalParticipants;
    private List<TeamSummaryDto> teams;
    private List<TopicDto> topics;
}
