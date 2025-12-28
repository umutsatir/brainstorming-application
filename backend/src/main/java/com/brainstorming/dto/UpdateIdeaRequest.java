package com.brainstorming.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateIdeaRequest {
    
    @NotBlank(message = "Idea text is required")
    @Size(max = 1000, message = "Idea text must be less than 1000 characters")
    private String text;
}
