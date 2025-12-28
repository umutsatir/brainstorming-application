package com.brainstorming.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateTeamRequest {

    @NotNull(message = "Event ID is required")
    private Long eventId;

    @NotBlank(message = "Team name is required")
    private String name;

    private String focus;

    @Min(value = 1, message = "Capacity must be at least 1")
    @Max(value = 6, message = "Capacity cannot exceed 6")
    private Integer capacity;
}
