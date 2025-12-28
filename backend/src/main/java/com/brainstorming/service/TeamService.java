package com.brainstorming.service;

import com.brainstorming.dto.CreateTeamRequest;
import com.brainstorming.dto.TeamDto;
import com.brainstorming.dto.UserDto;
import com.brainstorming.entity.Event;
import com.brainstorming.dto.*;
import com.brainstorming.entity.Team;
import com.brainstorming.entity.TeamMember;
import com.brainstorming.entity.User;
import com.brainstorming.mapper.TeamMapper;
import com.brainstorming.mapper.UserMapper;
import com.brainstorming.repository.EventRepository;
import com.brainstorming.repository.TeamMemberRepository;
import com.brainstorming.repository.TeamRepository;
import com.brainstorming.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final TeamRepository teamRepository;
    private final EventRepository eventRepository;
    private final UserRepository userRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final TeamMapper teamMapper;
    private final UserMapper userMapper;

    public List<TeamDto> getAllTeams() {
        return teamRepository.findAll().stream()
                .map(teamMapper::toDto)
                .collect(Collectors.toList());
    }

    public TeamDto getTeamById(Long id) {
        Team team = teamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Team not found"));
        return teamMapper.toDto(team);
    }

    @Transactional
    public TeamDto createTeam(CreateTeamRequest request, Long leaderId) {
        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new RuntimeException("Event not found"));

        User leader = userRepository.findById(leaderId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Team team = new Team();
        team.setName(request.getName());
        team.setFocus(request.getFocus());
        if (request.getCapacity() != null) {
            team.setCapacity(request.getCapacity());
        }
        team.setEvent(event);
        team.setLeader(leader);

        Team savedTeam = teamRepository.save(team);

        // Add leader as a member automatically
        addMembers(savedTeam.getId(), Collections.singletonList(leaderId));

        return teamMapper.toDto(savedTeam);
    }

    public TeamDto updateTeam(Long id, CreateTeamRequest request) {
        Team team = teamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Team not found"));

        if (request.getName() != null) {
            team.setName(request.getName());
        }
        if (request.getFocus() != null) {
            team.setFocus(request.getFocus());
        }
        if (request.getCapacity() != null) {
            team.setCapacity(request.getCapacity());
        }
        // Assuming leader update is logic heavy or handled separately, but simple field
        // update here:
        // if (request.getLeaderId() != null) ... (Need to fetch user etc. keeping
        // simple for now)

        return teamMapper.toDto(teamRepository.save(team));
    }

    public void deleteTeam(Long id) {
        Team team = teamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Team not found"));
        teamRepository.delete(team);
    }

    public List<UserDto> getTeamMembers(Long teamId) {
        List<TeamMember> members = teamMemberRepository.findByTeamId(teamId);
        return members.stream()
                .map(member -> userMapper.toDto(member.getUser()))
                .collect(Collectors.toList());
    }

    @Transactional
    public void addMembers(Long teamId, List<Long> userIds) {
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new RuntimeException("Team not found"));

        for (Long userId : userIds) {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found: " + userId));

            // Check if already member
            if (teamMemberRepository.findByTeamIdAndUserId(teamId, userId).isEmpty()) {
                TeamMember member = new TeamMember();
                member.setTeam(team);
                member.setUser(user);
                teamMemberRepository.save(member);
            }
        }
    }

    @Transactional
    public void removeMember(Long teamId, Long userId) {
        TeamMember member = teamMemberRepository.findByTeamIdAndUserId(teamId, userId)
                .orElseThrow(() -> new RuntimeException("Member not found in team"));
        teamMemberRepository.delete(member);
    }
}
