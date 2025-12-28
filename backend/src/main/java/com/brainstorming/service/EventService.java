package com.brainstorming.service;

import com.brainstorming.dto.CreateEventRequest;
import com.brainstorming.dto.EventDto;
import com.brainstorming.dto.TeamDto;
import com.brainstorming.dto.TopicDto;
import com.brainstorming.entity.Event;
import com.brainstorming.entity.Team;
import com.brainstorming.entity.Topic;
import com.brainstorming.entity.User;
import com.brainstorming.mapper.EventMapper;
import com.brainstorming.mapper.TeamMapper;
import com.brainstorming.mapper.TopicMapper;
import com.brainstorming.repository.EventRepository;
import com.brainstorming.repository.TeamRepository;
import com.brainstorming.repository.TopicRepository;
import com.brainstorming.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final TeamRepository teamRepository;
    private final TopicRepository topicRepository;
    private final UserRepository userRepository;
    private final EventMapper eventMapper;
    private final TeamMapper teamMapper;
    private final TopicMapper topicMapper;

    public List<EventDto> getAllEvents(User user) {
        // Fix: Compare Enum properly
        if (user == null || user.getRole() == User.Role.EVENT_MANAGER) {
            return eventRepository.findAll().stream()
                    .map(eventMapper::toDto)
                    .collect(Collectors.toList());
        }

        // If TEAM_LEADER, find teams they lead and return unique events
        if (user.getRole() == User.Role.TEAM_LEADER) {
            List<Team> teams = teamRepository.findByLeaderId(user.getId());
            return teams.stream()
                    .map(Team::getEvent)
                    .distinct() // Ensure unique events
                    .map(eventMapper::toDto)
                    .collect(Collectors.toList());
        }

        // Default: return empty
        return List.of();
    }

    public List<EventDto> getAllEvents() {
        return eventRepository.findAll().stream()
                .map(eventMapper::toDto)
                .collect(Collectors.toList());
    }

    public EventDto getEventById(Long id) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));
        return eventMapper.toDto(event);
    }

    @Transactional
    public EventDto createEvent(CreateEventRequest request, Long ownerId) {
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Event event = new Event();
        event.setName(request.getName());
        event.setDescription(request.getDescription());
        event.setStartDate(request.getStartDate());
        event.setEndDate(request.getEndDate());
        event.setOwner(owner);

        Event savedEvent = eventRepository.save(event);
        return eventMapper.toDto(savedEvent);
    }

    @Transactional
    public EventDto updateEvent(Long id, CreateEventRequest request) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        if (request.getName() != null) {
            event.setName(request.getName());
        }
        if (request.getDescription() != null) {
            event.setDescription(request.getDescription());
        }
        if (request.getStartDate() != null) {
            event.setStartDate(request.getStartDate());
        }
        if (request.getEndDate() != null) {
            event.setEndDate(request.getEndDate());
        }

        Event updatedEvent = eventRepository.save(event);
        return eventMapper.toDto(updatedEvent);
    }

    @Transactional
    public void deleteEvent(Long id) {
        if (!eventRepository.existsById(id)) {
            throw new RuntimeException("Event not found");
        }
        eventRepository.deleteById(id);
    }

    public List<TeamDto> getEventTeams(Long eventId) {
        List<Team> teams = teamRepository.findByEventId(eventId);
        return teams.stream()
                .map(teamMapper::toDto)
                .collect(Collectors.toList());
    }

}
