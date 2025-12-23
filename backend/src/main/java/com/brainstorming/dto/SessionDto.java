package com.brainstorming.dto;

import com.brainstorming.entity.Session;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionDto {
    private Long id;
    private Long teamId;
    private String teamName;
    private Long topicId;
    private String topicTitle;
    private Session.Status status;
    private Integer currentRound;
    private Integer roundCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
