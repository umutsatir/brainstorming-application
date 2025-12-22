package com.brainstorming.mapper;

import com.brainstorming.dto.TeamMemberDto;
import com.brainstorming.entity.TeamMember;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface TeamMemberMapper {
    
    @Mapping(source = "team.id", target = "teamId")
    @Mapping(source = "user.id", target = "userId")
    @Mapping(source = "user.fullName", target = "userName")
    @Mapping(source = "user.email", target = "userEmail")
    TeamMemberDto toDto(TeamMember teamMember);
    
    List<TeamMemberDto> toDtoList(List<TeamMember> teamMembers);
}
