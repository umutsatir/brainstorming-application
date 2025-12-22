package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IdeaDto {
    private Long id;
    private Long sessionId;
    private Long roundId;
    private Integer roundNumber;
    private Long teamId;
    private Long authorId;
    private String authorName;
    private String text;
    private Long passedFromUserId;
    private String passedFromUserName;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
