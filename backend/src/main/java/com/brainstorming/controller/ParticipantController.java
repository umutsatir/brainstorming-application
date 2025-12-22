package com.brainstorming.controller;

import com.brainstorming.dto.CreateParticipantRequest;
import com.brainstorming.dto.EventParticipantDto;
import com.brainstorming.dto.ParticipantResponse;
import com.brainstorming.dto.UpdateParticipantRequest;
import com.brainstorming.entity.Event;
import com.brainstorming.entity.EventParticipant;
import com.brainstorming.entity.User;
import com.brainstorming.exception.BadRequestException;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.mapper.EventParticipantMapper;
import com.brainstorming.repository.EventParticipantRepository;
import com.brainstorming.repository.EventRepository;
import com.brainstorming.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Participant Controller - Manages event participants and their roles.
 * Covers FR-101–114, Scenario 2, User Registration / Management flow.
 * 
 * Role-based access control:
 * - POST /participants: EVENT_MANAGER only (FR-101)
 * - GET /participants: EVENT_MANAGER (full), TEAM_LEADER (own team only) (FR-106–107)
 * - GET /participants/{id}: EVENT_MANAGER (full), TEAM_LEADER (own team), SELF (own record)
 * - PATCH /participants/{id}: EVENT_MANAGER only (FR-110)
 * - DELETE /participants/{id}: EVENT_MANAGER only (FR-114)
 */
@RestController
@RequestMapping("/api/participants")
@RequiredArgsConstructor
public class ParticipantController {
    
    private final EventParticipantRepository participantRepository;
    private final EventRepository eventRepository;
    private final UserRepository userRepository;
    private final EventParticipantMapper participantMapper;
    
    /**
     * POST /participants
     * Roles: EVENT_MANAGER
     * Use: Register participant manually (FR-101).
     * Body: fullName, email, phone, role, eventId.
     * Response: 201 { id, fullName, role, status, eventId }
     */
    @PostMapping
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<ParticipantResponse> createParticipant(
            @Valid @RequestBody CreateParticipantRequest request) {
        
        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + request.getEventId()));
        
        // Check if user with email already exists
        User user = userRepository.findByEmail(request.getEmail()).orElse(null);
        
        if (user == null) {
            // Create new user with INVITED status
            user = User.builder()
                    .fullName(request.getFullName())
                    .email(request.getEmail())
                    .phone(request.getPhone())
                    .role(User.Role.valueOf(request.getRole()))
                    .status(User.Status.INVITED)
                    .passwordHash("") // Will be set when user accepts invitation
                    .build();
            user = userRepository.save(user);
        }
        
        // Check if user is already a participant in this event
        if (participantRepository.existsByEventIdAndUserId(request.getEventId(), user.getId())) {
            throw new BadRequestException("User is already a participant in this event");
        }
        
        // Create event participant
        EventParticipant participant = new EventParticipant();
        participant.setEvent(event);
        participant.setUser(user);
        participant.setRoleOverride(User.Role.valueOf(request.getRole()));
        
        EventParticipant saved = participantRepository.save(participant);
        
        // TODO: Optionally send invitation email
        
        ParticipantResponse response = ParticipantResponse.builder()
                .id(saved.getId())
                .fullName(user.getFullName())
                .role(request.getRole())
                .status(user.getStatus().name())
                .eventId(event.getId())
                .build();
        
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    /**
     * GET /participants
     * Roles: EVENT_MANAGER (full list), TEAM_LEADER (own team members only) (FR-106–107)
     * Query params: eventId, teamId, role, pagination
     * Response: 200 list of participants (fields filtered based on role)
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<List<EventParticipantDto>> getParticipants(
            @RequestParam(required = false) Long eventId,
            @RequestParam(required = false) Long teamId,
            @RequestParam(required = false) String role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        // TODO: Implement role-based filtering
        // - EVENT_MANAGER: sees all participants
        // - TEAM_LEADER: only sees own team members
        
        List<EventParticipant> participants;
        if (eventId != null) {
            participants = participantRepository.findByEventId(eventId);
        } else {
            participants = participantRepository.findAll();
        }
        
        // TODO: Apply teamId and role filters
        // TODO: Apply pagination
        // TODO: Filter fields based on caller's role
        
        return ResponseEntity.ok(participantMapper.toDtoList(participants));
    }
    
    /**
     * GET /participants/{id}
     * Roles: EVENT_MANAGER (full), TEAM_LEADER (members in own team), SELF (own record)
     * Use: Get detailed participant info.
     * Response: 200 participant details or 403/404
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER', 'TEAM_MEMBER')")
    public ResponseEntity<EventParticipantDto> getParticipant(@PathVariable Long id) {
        EventParticipant participant = participantRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Participant not found with id: " + id));
        
        // TODO: Implement access control logic:
        // - EVENT_MANAGER: can view any participant
        // - TEAM_LEADER: can only view members in own team
        // - SELF: can only view own record
        // Return 403 if access denied
        
        return ResponseEntity.ok(participantMapper.toDto(participant));
    }
    
    /**
     * PATCH /participants/{id}
     * Roles: EVENT_MANAGER
     * Use: Update contact info, role, status (FR-110)
     * Body: Partial { fullName?, phone?, role?, status? }
     * Responsibilities: Validate role transitions (e.g., Team Leader must be member of a team)
     * Response: 200 updated participant
     */
    @PatchMapping("/{id}")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<EventParticipantDto> updateParticipant(
            @PathVariable Long id,
            @RequestBody UpdateParticipantRequest request) {
        
        EventParticipant participant = participantRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Participant not found with id: " + id));
        
        User user = participant.getUser();
        
        // Update user fields if provided
        if (request.getFullName() != null && !request.getFullName().isEmpty()) {
            user.setFullName(request.getFullName());
        }
        if (request.getPhone() != null) {
            user.setPhone(request.getPhone());
        }
        if (request.getStatus() != null && !request.getStatus().isEmpty()) {
            user.setStatus(User.Status.valueOf(request.getStatus()));
        }
        
        userRepository.save(user);
        
        // Update role override if provided
        if (request.getRole() != null && !request.getRole().isEmpty()) {
            User.Role newRole = User.Role.valueOf(request.getRole());
            
            // TODO: Validate role transitions
            // e.g., Team Leader must be member of a team
            
            participant.setRoleOverride(newRole);
        }
        
        EventParticipant saved = participantRepository.save(participant);
        
        return ResponseEntity.ok(participantMapper.toDto(saved));
    }
    
    /**
     * DELETE /participants/{id}
     * Roles: EVENT_MANAGER
     * Use: Remove participant from event roster (FR-114)
     * Response: 204 No Content
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<Void> deleteParticipant(@PathVariable Long id) {
        if (!participantRepository.existsById(id)) {
            throw new ResourceNotFoundException("Participant not found with id: " + id);
        }
        
        participantRepository.deleteById(id);
        
        return ResponseEntity.noContent().build();
    }
}
