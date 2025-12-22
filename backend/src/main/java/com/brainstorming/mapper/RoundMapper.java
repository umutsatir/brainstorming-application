package com.brainstorming.mapper;

import com.brainstorming.dto.RoundDto;
import com.brainstorming.entity.Round;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface RoundMapper {
    
    @Mapping(source = "session.id", target = "sessionId")
    RoundDto toDto(Round round);
    
    List<RoundDto> toDtoList(List<Round> rounds);
}
