package com.brainstorming.controller;

import com.brainstorming.dto.UserDto;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import com.brainstorming.entity.User;
import com.brainstorming.mapper.UserMapper;
import com.brainstorming.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final UserRepository userRepository;
    private final UserMapper userMapper;
    
    /**
     * GET /users - Get paginated list of all users.
     * Supports search by name or email.
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER')")
    public ResponseEntity<Page<UserDto>> getAllUsers(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(userService.getAllUsers(search, page, size));
    }
    
    /**
     * GET /users/{id} - Get user by ID.
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('EVENT_MANAGER', 'TEAM_LEADER', 'TEAM_MEMBER')")
    public ResponseEntity<UserDto> getUserById(@PathVariable Long id) {
        return userService.getUserById(id)
                .map(ResponseEntity::ok)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<UserDto> updateUser(@PathVariable Long id, @RequestBody UserDto userDto) {
        // TODO: Implement update user
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('EVENT_MANAGER')")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
