package com.brainstorming.service;

import com.brainstorming.dto.*;
import com.brainstorming.entity.*;
import com.brainstorming.exception.BadRequestException;
import com.brainstorming.exception.ResourceNotFoundException;
import com.brainstorming.exception.UnauthorizedException;
import com.brainstorming.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class IdeaService {

    private final IdeaRepository ideaRepository;
    private final SessionRepository sessionRepository;
    private final RoundRepository roundRepository;
    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final UserRepository userRepository;

    public List<IdeaDto> getAllIdeas() {
        return ideaRepository.findAll().stream()
                .map(this::mapToIdeaDto)
                .collect(Collectors.toList());
    }

    public IdeaDto getIdea(Long ideaId) {
        Idea idea = ideaRepository.findById(ideaId)
                .orElseThrow(() -> new ResourceNotFoundException("Idea not found"));
        return mapToIdeaDto(idea);
    }

    public List<IdeaDto> getIdeasBySession(Long sessionId) {
        return ideaRepository.findBySessionId(sessionId).stream()
                .map(this::mapToIdeaDto)
                .collect(Collectors.toList());
    }

    public List<IdeaDto> getIdeasByRound(Long sessionId, Integer roundNumber) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));

        Round round = roundRepository.findBySessionIdAndRoundNumber(sessionId, roundNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Round not found"));

        return ideaRepository.findBySessionIdAndRoundId(sessionId, round.getId()).stream()
                .map(this::mapToIdeaDto)
                .collect(Collectors.toList());
    }

    public List<IdeaDto> getIdeasForRound(Long sessionId, Integer roundNumber) {
        return getIdeasByRound(sessionId, roundNumber);
    }

    public List<IdeaDto> getPreviousRoundIdeas(Long sessionId, Integer currentRoundNumber, Long userId) {
        if (currentRoundNumber <= 1) {
            return new ArrayList<>();
        }

        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));

        Team team = session.getTeam();

        // Get ordered participants
        List<User> participants = getOrderedParticipants(team);
        List<Long> participantIds = participants.stream().map(User::getId).collect(Collectors.toList());

        // Find the previous user in rotation
        int userIndex = participantIds.indexOf(userId);
        if (userIndex == -1) {
            throw new UnauthorizedException("You are not a participant in this session");
        }
        int previousIndex = userIndex > 0 ? userIndex - 1 : participantIds.size() - 1;
        Long previousUserId = participantIds.get(previousIndex);

        // Get previous round
        Round prevRound = roundRepository.findBySessionIdAndRoundNumber(sessionId, currentRoundNumber - 1)
                .orElseThrow(() -> new ResourceNotFoundException("Previous round not found"));

        // Get ideas from previous user in previous round
        return ideaRepository.findBySessionIdAndRoundId(sessionId, prevRound.getId()).stream()
                .filter(idea -> idea.getAuthor().getId().equals(previousUserId))
                .map(this::mapToIdeaDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public SubmitIdeasResponse submitIdeas(Long sessionId, Integer roundNumber, Long userId, SubmitIdeasRequest request) {
        // Validate session
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));

        // Check session is running
        if (session.getStatus() != Session.Status.RUNNING) {
            throw new BadRequestException("Session is not running");
        }

        // Check round matches current round
        if (!session.getCurrentRound().equals(roundNumber)) {
            throw new BadRequestException("This round is not active");
        }

        // Get round
        Round round = roundRepository.findBySessionIdAndRoundNumber(sessionId, roundNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Round not found"));

        // Check round is still active
        if (round.getTimerState() == Round.TimerState.FINISHED) {
            throw new BadRequestException("This round has ended");
        }

        // Check user can submit (member or leader)
        Team team = session.getTeam();
        boolean isLeader = team.getLeader().getId().equals(userId);
        boolean isMember = teamMemberRepository.existsByTeamIdAndUserId(team.getId(), userId);

        if (!isLeader && !isMember) {
            throw new UnauthorizedException("Only team members and leaders can submit ideas");
        }

        // Check user hasn't already submitted
        List<Idea> existingIdeas = ideaRepository.findBySessionIdAndRoundId(sessionId, round.getId()).stream()
                .filter(idea -> idea.getAuthor().getId().equals(userId))
                .collect(Collectors.toList());

        if (!existingIdeas.isEmpty()) {
            throw new BadRequestException("You have already submitted ideas for this round");
        }

        // Validate ideas
        List<String> ideas = request.getIdeas();
        if (ideas == null || ideas.size() != 3) {
            throw new BadRequestException("You must submit exactly 3 ideas");
        }

        // Trim and validate non-empty
        List<String> trimmedIdeas = ideas.stream()
                .map(String::trim)
                .collect(Collectors.toList());

        if (trimmedIdeas.stream().anyMatch(String::isEmpty)) {
            throw new BadRequestException("All ideas must be non-empty");
        }

        // Check uniqueness
        Set<String> uniqueIdeas = new HashSet<>(trimmedIdeas.stream()
                .map(String::toLowerCase)
                .collect(Collectors.toList()));
        if (uniqueIdeas.size() != 3) {
            throw new BadRequestException("All ideas must be unique");
        }

        // Get user
        User author = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Get previous member for idea passing
        List<User> participants = getOrderedParticipants(team);
        List<Long> participantIds = participants.stream().map(User::getId).collect(Collectors.toList());
        int userIndex = participantIds.indexOf(userId);
        int previousIndex = userIndex > 0 ? userIndex - 1 : participantIds.size() - 1;
        Long previousUserId = roundNumber > 1 ? participantIds.get(previousIndex) : null;

        User passedFromUser = null;
        if (previousUserId != null) {
            passedFromUser = userRepository.findById(previousUserId).orElse(null);
        }

        // Create ideas
        List<Idea> savedIdeas = new ArrayList<>();
        for (String ideaText : trimmedIdeas) {
            Idea idea = Idea.builder()
                    .session(session)
                    .round(round)
                    .team(team)
                    .author(author)
                    .text(ideaText)
                    .passedFromUser(passedFromUser)
                    .build();
            savedIdeas.add(ideaRepository.save(idea));
        }

        return SubmitIdeasResponse.builder()
                .message("Ideas submitted successfully")
                .ideas(savedIdeas.stream().map(this::mapToIdeaDto).collect(Collectors.toList()))
                .build();
    }

    @Transactional
    public IdeaDto createIdea(CreateIdeaRequest request, Long authorId) {
        Session session = sessionRepository.findById(request.getSessionId())
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));

        Round round = roundRepository.findById(request.getRoundId())
                .orElseThrow(() -> new ResourceNotFoundException("Round not found"));

        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        User passedFromUser = null;
        if (request.getPassedFromUserId() != null) {
            passedFromUser = userRepository.findById(request.getPassedFromUserId()).orElse(null);
        }

        Idea idea = Idea.builder()
                .session(session)
                .round(round)
                .team(session.getTeam())
                .author(author)
                .text(request.getText())
                .passedFromUser(passedFromUser)
                .build();

        return mapToIdeaDto(ideaRepository.save(idea));
    }

    @Transactional
    public IdeaDto updateIdea(Long ideaId, CreateIdeaRequest request, Long userId) {
        Idea idea = ideaRepository.findById(ideaId)
                .orElseThrow(() -> new ResourceNotFoundException("Idea not found"));

        // Only author can update
        if (!idea.getAuthor().getId().equals(userId)) {
            throw new UnauthorizedException("You can only update your own ideas");
        }

        idea.setText(request.getText());
        return mapToIdeaDto(ideaRepository.save(idea));
    }

    @Transactional
    public void deleteIdea(Long ideaId, Long userId) {
        Idea idea = ideaRepository.findById(ideaId)
                .orElseThrow(() -> new ResourceNotFoundException("Idea not found"));

        // Only author can delete
        if (!idea.getAuthor().getId().equals(userId)) {
            throw new UnauthorizedException("You can only delete your own ideas");
        }

        ideaRepository.delete(idea);
    }

    /**
     * Get round ideas with submission status for a user (7.1)
     * Shows previous teammate ideas, user's own ideas, and submission counts
     */
    public RoundIdeasResponseDto getRoundIdeasForUser(Long sessionId, Integer roundNumber, Long userId) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));

        Team team = session.getTeam();
        
        // Check user belongs to team
        boolean isLeader = team.getLeader().getId().equals(userId);
        boolean isMember = teamMemberRepository.existsByTeamIdAndUserId(team.getId(), userId);
        boolean isManager = team.getEvent().getOwner().getId().equals(userId);
        
        if (!isLeader && !isMember && !isManager) {
            throw new UnauthorizedException("You don't have access to this session");
        }

        Round round = roundRepository.findBySessionIdAndRoundNumber(sessionId, roundNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Round not found"));

        List<User> participants = getOrderedParticipants(team);
        List<Long> participantIds = participants.stream().map(User::getId).collect(Collectors.toList());

        // Get all ideas for this round
        List<Idea> roundIdeas = ideaRepository.findBySessionIdAndRoundId(sessionId, round.getId());

        // Get user's own ideas
        List<IdeaDto> yourIdeas = roundIdeas.stream()
                .filter(idea -> idea.getAuthor().getId().equals(userId))
                .map(this::mapToIdeaDto)
                .collect(Collectors.toList());

        // Get previous teammate's ideas (from previous round)
        List<IdeaDto> previousTeammateIdeas = new ArrayList<>();
        if (roundNumber > 1) {
            int userIndex = participantIds.indexOf(userId);
            if (userIndex >= 0) {
                int prevUserIndex = userIndex > 0 ? userIndex - 1 : participantIds.size() - 1;
                Long prevUserId = participantIds.get(prevUserIndex);
                
                Round prevRound = roundRepository.findBySessionIdAndRoundNumber(sessionId, roundNumber - 1)
                        .orElse(null);
                if (prevRound != null) {
                    previousTeammateIdeas = ideaRepository.findBySessionIdAndRoundId(sessionId, prevRound.getId())
                            .stream()
                            .filter(idea -> idea.getAuthor().getId().equals(prevUserId))
                            .map(this::mapToIdeaDto)
                            .collect(Collectors.toList());
                }
            }
        }

        // Calculate submission status
        int submittedCount = 0;
        for (Long participantId : participantIds) {
            long ideaCount = roundIdeas.stream()
                    .filter(idea -> idea.getAuthor().getId().equals(participantId))
                    .count();
            if (ideaCount >= 3) submittedCount++;
        }

        return RoundIdeasResponseDto.builder()
                .roundNumber(roundNumber)
                .previousTeammateIdeas(previousTeammateIdeas)
                .yourIdeas(yourIdeas)
                .submissionStatus(RoundIdeasResponseDto.SubmissionStatusDto.builder()
                        .submittedCount(submittedCount)
                        .totalMembers(participants.size())
                        .build())
                .build();
    }

    /**
     * Update an idea (7.3)
     * User can edit their own idea before round lock
     */
    @Transactional
    public IdeaDto updateIdea(Long ideaId, UpdateIdeaRequest request, Long userId) {
        Idea idea = ideaRepository.findById(ideaId)
                .orElseThrow(() -> new ResourceNotFoundException("Idea not found"));

        Session session = idea.getSession();
        Round round = idea.getRound();
        Team team = session.getTeam();

        // Check if round is still active (not finished)
        if (round.getTimerState() == Round.TimerState.FINISHED) {
            // Allow leader/manager to edit even after round ends (moderation)
            boolean isLeader = team.getLeader().getId().equals(userId);
            boolean isManager = team.getEvent().getOwner().getId().equals(userId);
            if (!isLeader && !isManager) {
                throw new BadRequestException("Round has ended, ideas cannot be edited");
            }
        } else {
            // During round, only author can edit
            if (!idea.getAuthor().getId().equals(userId)) {
                throw new UnauthorizedException("You can only edit your own ideas");
            }
        }

        idea.setText(request.getText().trim());
        return mapToIdeaDto(ideaRepository.save(idea));
    }

    private List<User> getOrderedParticipants(Team team) {
        List<User> participants = new ArrayList<>();

        // Add leader first (sort order 0)
        participants.add(team.getLeader());

        // Add team members ordered by id
        List<TeamMember> members = teamMemberRepository.findByTeamId(team.getId());
        members.stream()
                .sorted(Comparator.comparing(TeamMember::getId))
                .map(TeamMember::getUser)
                .filter(user -> !user.getId().equals(team.getLeader().getId()))
                .forEach(participants::add);

        return participants;
    }

    private IdeaDto mapToIdeaDto(Idea idea) {
        return IdeaDto.builder()
                .id(idea.getId())
                .sessionId(idea.getSession().getId())
                .roundId(idea.getRound().getId())
                .roundNumber(idea.getRound().getRoundNumber())
                .teamId(idea.getTeam().getId())
                .authorId(idea.getAuthor().getId())
                .authorName(idea.getAuthor().getFullName())
                .text(idea.getText())
                .passedFromUserId(idea.getPassedFromUser() != null ? idea.getPassedFromUser().getId() : null)
                .passedFromUserName(idea.getPassedFromUser() != null ? idea.getPassedFromUser().getFullName() : null)
                .createdAt(idea.getCreatedAt())
                .updatedAt(idea.getUpdatedAt())
                .build();
    }
}
