package com.brainstorming.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SubmitIdeasRequest {
    
    @NotNull(message = "Ideas are required")
    @Size(min = 3, max = 3, message = "You must submit exactly 3 ideas")
    private List<@NotEmpty(message = "Idea text cannot be empty") String> ideas;
}
