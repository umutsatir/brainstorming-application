package com.brainstorming.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionLogDto {
    private Long id;
    private Long sessionId;
    private Long userId;
    private String userName;
    private String actionType;
    private String payload;
    private LocalDateTime createdAt;
}
