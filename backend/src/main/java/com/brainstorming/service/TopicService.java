package com.brainstorming.service;

import com.brainstorming.dto.CreateTopicRequest;
import com.brainstorming.dto.TopicDto;
import com.brainstorming.dto.UpdateTopicRequest;
import com.brainstorming.entity.Event;
import com.brainstorming.entity.Topic;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.mapper.TopicMapper;
import com.brainstorming.repository.EventRepository;
import com.brainstorming.repository.TopicRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TopicService {

    private final TopicRepository topicRepository;
    private final EventRepository eventRepository;
    private final TopicMapper topicMapper;

    @Transactional
    public TopicDto createTopic(Long eventId, CreateTopicRequest request) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + eventId));

        Topic topic = new Topic();
        topic.setEvent(event);
        topic.setTitle(request.getTitle());
        topic.setDescription(request.getDescription());
        topic.setStatus(Topic.Status.OPEN);

        Topic savedTopic = topicRepository.save(topic);
        return topicMapper.toDto(savedTopic);
    }

    public List<TopicDto> getTopicsByEventId(Long eventId) {
        if (!eventRepository.existsById(eventId)) {
            throw new ResourceNotFoundException("Event not found with id: " + eventId);
        }
        List<Topic> topics = topicRepository.findByEventId(eventId);
        return topicMapper.toDtoList(topics);
    }

    public TopicDto getTopicById(Long topicId) {
        Topic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new ResourceNotFoundException("Topic not found with id: " + topicId));
        return topicMapper.toDto(topic);
    }

    @Transactional
    public TopicDto updateTopic(Long topicId, UpdateTopicRequest request) {
        Topic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new ResourceNotFoundException("Topic not found with id: " + topicId));

        // Maybe prevent changes after event closed? 
        // Requirement says: "maybe prevent changes after event closed."
        // For now, I will just update the fields if they are present.

        if (request.getTitle() != null) {
            topic.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            topic.setDescription(request.getDescription());
        }
        if (request.getStatus() != null) {
            topic.setStatus(request.getStatus());
        }

        Topic updatedTopic = topicRepository.save(topic);
        return topicMapper.toDto(updatedTopic);
    }

    @Transactional
    public void deleteTopic(Long topicId) {
        if (!topicRepository.existsById(topicId)) {
            throw new ResourceNotFoundException("Topic not found with id: " + topicId);
        }
        topicRepository.deleteById(topicId);
    }
}
