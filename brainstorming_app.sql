-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Anamakine: localhost
-- Üretim Zamanı: 14 Ara 2025, 22:26:35
-- Sunucu sürümü: 9.5.0
-- PHP Sürümü: 8.5.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Veritabanı: `brainstorming_app`
--

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ai_artifacts`
--

CREATE TABLE `ai_artifacts` (
  `id` bigint NOT NULL,
  `session_id` bigint NOT NULL,
  `round_id` bigint DEFAULT NULL,
  `type` enum('SUGGESTION','SUMMARY') COLLATE utf8mb4_general_ci NOT NULL,
  `content` json NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `events`
--

CREATE TABLE `events` (
  `id` bigint NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `owner_id` bigint NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `event_participants`
--

CREATE TABLE `event_participants` (
  `id` bigint NOT NULL,
  `event_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `role_override` enum('EVENT_MANAGER','TEAM_LEADER','TEAM_MEMBER') COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ideas`
--

CREATE TABLE `ideas` (
  `id` bigint NOT NULL,
  `session_id` bigint NOT NULL,
  `round_id` bigint NOT NULL,
  `team_id` bigint NOT NULL,
  `author_id` bigint NOT NULL,
  `text` text COLLATE utf8mb4_general_ci NOT NULL,
  `passed_from_user_id` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `device_token` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `device_type` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `realtime_tokens`
--

CREATE TABLE `realtime_tokens` (
  `id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `reports_cache`
--

CREATE TABLE `reports_cache` (
  `id` bigint NOT NULL,
  `session_id` bigint NOT NULL,
  `format` enum('pdf','csv') COLLATE utf8mb4_general_ci DEFAULT NULL,
  `file_path` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `rounds`
--

CREATE TABLE `rounds` (
  `id` bigint NOT NULL,
  `session_id` bigint NOT NULL,
  `round_number` int NOT NULL,
  `start_time` timestamp NULL DEFAULT NULL,
  `end_time` timestamp NULL DEFAULT NULL,
  `timer_state` enum('RUNNING','PAUSED','FINISHED') COLLATE utf8mb4_general_ci DEFAULT 'RUNNING',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `sessions`
--

CREATE TABLE `sessions` (
  `id` bigint NOT NULL,
  `team_id` bigint NOT NULL,
  `topic_id` bigint NOT NULL,
  `status` enum('PENDING','RUNNING','PAUSED','COMPLETED') COLLATE utf8mb4_general_ci DEFAULT 'PENDING',
  `current_round` int DEFAULT '1',
  `round_count` int DEFAULT '5',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `session_logs`
--

CREATE TABLE `session_logs` (
  `id` bigint NOT NULL,
  `session_id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `action_type` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `payload` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `teams`
--

CREATE TABLE `teams` (
  `id` bigint NOT NULL,
  `event_id` bigint NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `leader_id` bigint NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `team_members`
--

CREATE TABLE `team_members` (
  `id` bigint NOT NULL,
  `team_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `topics`
--

CREATE TABLE `topics` (
  `id` bigint NOT NULL,
  `event_id` bigint NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `status` enum('OPEN','CLOSED','ARCHIVED') COLLATE utf8mb4_general_ci DEFAULT 'OPEN',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `users`
--

CREATE TABLE `users` (
  `id` bigint NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `phone` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `role` enum('EVENT_MANAGER','TEAM_LEADER','TEAM_MEMBER') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'TEAM_MEMBER',
  `status` enum('ACTIVE','INACTIVE','INVITED') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dökümü yapılmış tablolar için indeksler
--

--
-- Tablo için indeksler `ai_artifacts`
--
ALTER TABLE `ai_artifacts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `session_id` (`session_id`),
  ADD KEY `round_id` (`round_id`);

--
-- Tablo için indeksler `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner_id` (`owner_id`);

--
-- Tablo için indeksler `event_participants`
--
ALTER TABLE `event_participants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `event_id` (`event_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `ideas`
--
ALTER TABLE `ideas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `session_id` (`session_id`),
  ADD KEY `round_id` (`round_id`),
  ADD KEY `team_id` (`team_id`),
  ADD KEY `author_id` (`author_id`),
  ADD KEY `passed_from_user_id` (`passed_from_user_id`);

--
-- Tablo için indeksler `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `realtime_tokens`
--
ALTER TABLE `realtime_tokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `reports_cache`
--
ALTER TABLE `reports_cache`
  ADD PRIMARY KEY (`id`),
  ADD KEY `session_id` (`session_id`);

--
-- Tablo için indeksler `rounds`
--
ALTER TABLE `rounds`
  ADD PRIMARY KEY (`id`),
  ADD KEY `session_id` (`session_id`);

--
-- Tablo için indeksler `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `team_id` (`team_id`),
  ADD KEY `topic_id` (`topic_id`);

--
-- Tablo için indeksler `session_logs`
--
ALTER TABLE `session_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `session_id` (`session_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `teams`
--
ALTER TABLE `teams`
  ADD PRIMARY KEY (`id`),
  ADD KEY `event_id` (`event_id`),
  ADD KEY `leader_id` (`leader_id`);

--
-- Tablo için indeksler `team_members`
--
ALTER TABLE `team_members`
  ADD PRIMARY KEY (`id`),
  ADD KEY `team_id` (`team_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `topics`
--
ALTER TABLE `topics`
  ADD PRIMARY KEY (`id`),
  ADD KEY `event_id` (`event_id`);

--
-- Tablo için indeksler `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `ai_artifacts`
--
ALTER TABLE `ai_artifacts`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `events`
--
ALTER TABLE `events`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `event_participants`
--
ALTER TABLE `event_participants`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `ideas`
--
ALTER TABLE `ideas`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `realtime_tokens`
--
ALTER TABLE `realtime_tokens`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `reports_cache`
--
ALTER TABLE `reports_cache`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `rounds`
--
ALTER TABLE `rounds`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `sessions`
--
ALTER TABLE `sessions`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `session_logs`
--
ALTER TABLE `session_logs`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `teams`
--
ALTER TABLE `teams`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `team_members`
--
ALTER TABLE `team_members`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `topics`
--
ALTER TABLE `topics`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Tablo için AUTO_INCREMENT değeri `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Dökümü yapılmış tablolar için kısıtlamalar
--

--
-- Tablo kısıtlamaları `ai_artifacts`
--
ALTER TABLE `ai_artifacts`
  ADD CONSTRAINT `ai_artifacts_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `sessions` (`id`),
  ADD CONSTRAINT `ai_artifacts_ibfk_2` FOREIGN KEY (`round_id`) REFERENCES `rounds` (`id`);

--
-- Tablo kısıtlamaları `events`
--
ALTER TABLE `events`
  ADD CONSTRAINT `events_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `event_participants`
--
ALTER TABLE `event_participants`
  ADD CONSTRAINT `event_participants_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`),
  ADD CONSTRAINT `event_participants_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `ideas`
--
ALTER TABLE `ideas`
  ADD CONSTRAINT `ideas_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `sessions` (`id`),
  ADD CONSTRAINT `ideas_ibfk_2` FOREIGN KEY (`round_id`) REFERENCES `rounds` (`id`),
  ADD CONSTRAINT `ideas_ibfk_3` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`),
  ADD CONSTRAINT `ideas_ibfk_4` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `ideas_ibfk_5` FOREIGN KEY (`passed_from_user_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `realtime_tokens`
--
ALTER TABLE `realtime_tokens`
  ADD CONSTRAINT `realtime_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `reports_cache`
--
ALTER TABLE `reports_cache`
  ADD CONSTRAINT `reports_cache_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `sessions` (`id`);

--
-- Tablo kısıtlamaları `rounds`
--
ALTER TABLE `rounds`
  ADD CONSTRAINT `rounds_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `sessions` (`id`);

--
-- Tablo kısıtlamaları `sessions`
--
ALTER TABLE `sessions`
  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`),
  ADD CONSTRAINT `sessions_ibfk_2` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`);

--
-- Tablo kısıtlamaları `session_logs`
--
ALTER TABLE `session_logs`
  ADD CONSTRAINT `session_logs_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `sessions` (`id`),
  ADD CONSTRAINT `session_logs_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `teams`
--
ALTER TABLE `teams`
  ADD CONSTRAINT `teams_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`),
  ADD CONSTRAINT `teams_ibfk_2` FOREIGN KEY (`leader_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `team_members`
--
ALTER TABLE `team_members`
  ADD CONSTRAINT `team_members_ibfk_1` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`),
  ADD CONSTRAINT `team_members_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Tablo kısıtlamaları `topics`
--
ALTER TABLE `topics`
  ADD CONSTRAINT `topics_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`);
COMMIT;

ALTER TABLE `teams` ADD `focus` VARCHAR(128) NULL AFTER `leader_id`, ADD `capacity` TINYINT NOT NULL AFTER `focus`;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
