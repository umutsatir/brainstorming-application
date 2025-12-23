package com.brainstorming.mapper;

import com.brainstorming.dto.ReportDto;
import com.brainstorming.entity.ReportCache;
import org.mapstruct.*;

import java.util.List;

@Mapper(componentModel = "spring")
public interface ReportCacheMapper {
    
    @Mapping(target = "sessionId", source = "session.id")
    @Mapping(target = "sessionTopicTitle", source = "session.topic.title")
    @Mapping(target = "teamName", source = "session.team.name")
    ReportDto toDto(ReportCache reportCache);
    
    List<ReportDto> toDtoList(List<ReportCache> reportCaches);
}
