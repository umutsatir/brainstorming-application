package com.brainstorming.mapper;

import com.brainstorming.dto.SessionLogDto;
import com.brainstorming.entity.SessionLog;
import org.mapstruct.*;

import java.util.List;

@Mapper(componentModel = "spring")
public interface SessionLogMapper {
    
    @Mapping(target = "sessionId", source = "session.id")
    @Mapping(target = "userId", source = "user.id")
    @Mapping(target = "userName", source = "user.fullName")
    SessionLogDto toDto(SessionLog sessionLog);
    
    List<SessionLogDto> toDtoList(List<SessionLog> sessionLogs);
}
