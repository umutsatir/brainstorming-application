package com.brainstorming.dto;

import com.brainstorming.entity.ReportCache;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReportDto {
    private Long id;
    private Long sessionId;
    private String sessionTopicTitle;
    private String teamName;
    private ReportCache.Format format;
    private String filePath;
    private LocalDateTime createdAt;
}
