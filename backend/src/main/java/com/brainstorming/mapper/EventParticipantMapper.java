package com.brainstorming.mapper;

import com.brainstorming.dto.EventParticipantDto;
import com.brainstorming.entity.EventParticipant;
import org.mapstruct.*;

import java.util.List;

@Mapper(componentModel = "spring")
public interface EventParticipantMapper {
    
    @Mapping(target = "eventId", source = "event.id")
    @Mapping(target = "eventName", source = "event.name")
    @Mapping(target = "userId", source = "user.id")
    @Mapping(target = "userName", source = "user.fullName")
    @Mapping(target = "userEmail", source = "user.email")
    EventParticipantDto toDto(EventParticipant participant);
    
    List<EventParticipantDto> toDtoList(List<EventParticipant> participants);
}
