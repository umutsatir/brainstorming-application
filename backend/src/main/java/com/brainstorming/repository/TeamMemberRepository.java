package com.brainstorming.repository;

import com.brainstorming.entity.TeamMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TeamMemberRepository extends JpaRepository<TeamMember, Long> {

    List<TeamMember> findByTeamId(Long teamId);

    List<TeamMember> findByUserId(Long userId);

    Optional<TeamMember> findByTeamIdAndUserId(Long teamId, Long userId);

    boolean existsByTeamIdAndUserId(Long teamId, Long userId);

    void deleteByTeamIdAndUserId(Long teamId, Long userId);

    /**
     * Find all user IDs that are already members of teams in a specific event
     * @param eventId The event ID
     * @return List of user IDs already in teams for this event
     */
    @Query("SELECT DISTINCT tm.user.id FROM TeamMember tm WHERE tm.team.event.id = :eventId")
    List<Long> findUserIdsInEventTeams(@Param("eventId") Long eventId);
}
