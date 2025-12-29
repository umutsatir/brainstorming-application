package com.brainstorming.dto;

import com.brainstorming.entity.Topic;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateTopicRequest {
    private String title;
    private String description;
    private Topic.Status status;
}
