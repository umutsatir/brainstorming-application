package com.brainstorming.service;

import com.brainstorming.dto.UserDto;
import com.brainstorming.entity.User;
import com.brainstorming.repository.UserRepository;
import com.brainstorming.repository.TeamMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final TeamMemberRepository teamMemberRepository;

    /**
     * Get all users with pagination and optional search filter.
     * @param search Optional search query (matches full_name or email)
     * @param page Page number (0-based)
     * @param size Page size
     * @return Page of UserDto
     */
    public Page<UserDto> getAllUsers(String search, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("fullName").ascending());

        Page<User> usersPage;
        if (search != null && !search.isBlank()) {
            usersPage = userRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(
                    search, search, pageable);
        } else {
            usersPage = userRepository.findAll(pageable);
        }

        return usersPage.map(this::toDto);
    }

    /**
     * Get all users with pagination and optional search filter, excluding users already in teams for a specific event.
     * @param search Optional search query (matches full_name or email)
     * @param page Page number (0-based)
     * @param size Page size
     * @param eventId Event ID to check for existing team memberships
     * @return Page of UserDto excluding users already in teams
     */
    public Page<UserDto> getAllUsersExcludingEventTeamMembers(String search, int page, int size, Long eventId) {
        // Get all user IDs that are already in teams for this event
        List<Long> userIdsInTeams = teamMemberRepository.findUserIdsInEventTeams(eventId);

        Pageable pageable = PageRequest.of(page, size, Sort.by("fullName").ascending());

        Page<User> usersPage;
        if (search != null && !search.isBlank()) {
            usersPage = userRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(
                    search, search, pageable);
        } else {
            usersPage = userRepository.findAll(pageable);
        }

        // Filter out users who are already in teams for this event
        List<UserDto> filteredUsers = usersPage.getContent().stream()
                .filter(user -> !userIdsInTeams.contains(user.getId()))
                .map(this::toDto)
                .collect(Collectors.toList());

        // Create a new page with filtered results
        return new PageImpl<>(filteredUsers, pageable, usersPage.getTotalElements());
    }

    /**
     * Get user by ID.
     * @param id User ID
     * @return Optional UserDto
     */
    public Optional<UserDto> getUserById(Long id) {
        return userRepository.findById(id).map(this::toDto);
    }

    private UserDto toDto(User user) {
        UserDto dto = new UserDto();
        dto.setId(user.getId());
        dto.setFullName(user.getFullName());
        dto.setEmail(user.getEmail());
        dto.setPhone(user.getPhone());
        dto.setRole(user.getRole());
        dto.setStatus(user.getStatus());
        dto.setCreatedAt(user.getCreatedAt());
        dto.setUpdatedAt(user.getUpdatedAt());
        return dto;
    }
}
