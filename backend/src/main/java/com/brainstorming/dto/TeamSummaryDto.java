package com.brainstorming.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamSummaryDto {
    private Long id;
    private String name;
    private String leaderName;
    private Integer memberCount;
    private Integer sessionCount;
    private Integer totalIdeas;
}
