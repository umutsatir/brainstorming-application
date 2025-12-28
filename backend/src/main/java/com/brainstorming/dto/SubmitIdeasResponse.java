package com.brainstorming.dto;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SubmitIdeasResponse {
    private String message;
    private List<IdeaDto> ideas;
}
