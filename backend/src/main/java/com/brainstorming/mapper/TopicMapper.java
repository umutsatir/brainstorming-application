package com.brainstorming.mapper;

import com.brainstorming.dto.TopicDto;
import com.brainstorming.entity.Topic;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface TopicMapper {
    
    @Mapping(source = "event.id", target = "eventId")
    TopicDto toDto(Topic topic);
    
    List<TopicDto> toDtoList(List<Topic> topics);
    
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "event", ignore = true)
    @Mapping(target = "sessions", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Topic toEntity(TopicDto dto);
}
