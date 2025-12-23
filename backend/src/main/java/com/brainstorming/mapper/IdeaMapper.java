package com.brainstorming.mapper;

import com.brainstorming.dto.IdeaDto;
import com.brainstorming.entity.Idea;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface IdeaMapper {
    
    @Mapping(source = "session.id", target = "sessionId")
    @Mapping(source = "round.id", target = "roundId")
    @Mapping(source = "round.roundNumber", target = "roundNumber")
    @Mapping(source = "team.id", target = "teamId")
    @Mapping(source = "author.id", target = "authorId")
    @Mapping(source = "author.fullName", target = "authorName")
    @Mapping(source = "passedFromUser.id", target = "passedFromUserId")
    @Mapping(source = "passedFromUser.fullName", target = "passedFromUserName")
    IdeaDto toDto(Idea idea);
    
    List<IdeaDto> toDtoList(List<Idea> ideas);
}
