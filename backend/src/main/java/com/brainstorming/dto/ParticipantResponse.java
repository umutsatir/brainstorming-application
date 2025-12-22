package com.brainstorming.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ParticipantResponse {
    private Long id;
    private String fullName;
    private String role;
    private String status;
    private Long eventId;
}
