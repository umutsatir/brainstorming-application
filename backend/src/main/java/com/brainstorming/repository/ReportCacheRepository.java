package com.brainstorming.repository;

import com.brainstorming.entity.ReportCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReportCacheRepository extends JpaRepository<ReportCache, Long> {
    
    List<ReportCache> findBySessionId(Long sessionId);
    
    Optional<ReportCache> findBySessionIdAndFormat(Long sessionId, ReportCache.Format format);
}
