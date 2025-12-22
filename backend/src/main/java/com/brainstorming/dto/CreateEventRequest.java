package com.brainstorming.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateEventRequest {
    
    @NotBlank(message = "Event name is required")
    private String name;
    
    private String description;
    private LocalDate startDate;
    private LocalDate endDate;
}
