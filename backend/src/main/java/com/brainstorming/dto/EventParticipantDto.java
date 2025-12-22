package com.brainstorming.dto;

import com.brainstorming.entity.User;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventParticipantDto {
    private Long id;
    private Long eventId;
    private String eventName;
    private Long userId;
    private String userName;
    private String userEmail;
    private User.Role roleOverride;
    private LocalDateTime createdAt;
}
