package com.brainstorming.service;

import com.brainstorming.dto.UserDto;
import com.brainstorming.entity.User;
import com.brainstorming.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;

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
