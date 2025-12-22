package com.brainstorming.mapper;

import com.brainstorming.dto.TeamDto;
import com.brainstorming.entity.Team;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface TeamMapper {
    
    @Mapping(source = "event.id", target = "eventId")
    @Mapping(source = "leader.id", target = "leaderId")
    @Mapping(source = "leader.fullName", target = "leaderName")
    @Mapping(target = "memberCount", expression = "java(team.getMembers() != null ? team.getMembers().size() : 0)")
    TeamDto toDto(Team team);
    
    List<TeamDto> toDtoList(List<Team> teams);
    
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "event", ignore = true)
    @Mapping(target = "leader", ignore = true)
    @Mapping(target = "members", ignore = true)
    @Mapping(target = "sessions", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Team toEntity(TeamDto dto);
}
