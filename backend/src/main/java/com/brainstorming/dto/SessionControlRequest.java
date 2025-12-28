package com.brainstorming.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionControlRequest {
    private String action; // start, pause, resume, end
}
