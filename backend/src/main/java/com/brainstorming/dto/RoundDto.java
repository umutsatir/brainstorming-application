package com.brainstorming.dto;

import com.brainstorming.entity.Round;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoundDto {
    private Long id;
    private Long sessionId;
    private Integer roundNumber;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Round.TimerState timerState;
    private LocalDateTime createdAt;
}
