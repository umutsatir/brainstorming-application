package com.brainstorming.dto;

import com.brainstorming.entity.Topic;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TopicDto {
    private Long id;
    private Long eventId;
    private String title;
    private String description;
    private Topic.Status status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
