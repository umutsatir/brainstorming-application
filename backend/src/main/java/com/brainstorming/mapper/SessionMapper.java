package com.brainstorming.mapper;

import com.brainstorming.dto.SessionDto;
import com.brainstorming.entity.Session;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface SessionMapper {
    
    @Mapping(source = "team.id", target = "teamId")
    @Mapping(source = "team.name", target = "teamName")
    @Mapping(source = "topic.id", target = "topicId")
    @Mapping(source = "topic.title", target = "topicTitle")
    SessionDto toDto(Session session);
    
    List<SessionDto> toDtoList(List<Session> sessions);
    
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "team", ignore = true)
    @Mapping(target = "topic", ignore = true)
    @Mapping(target = "rounds", ignore = true)
    @Mapping(target = "ideas", ignore = true)
    @Mapping(target = "logs", ignore = true)
    @Mapping(target = "aiArtifacts", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Session toEntity(SessionDto dto);
}
