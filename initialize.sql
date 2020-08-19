-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 19, 2020 at 09:45 AM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.4.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `autocomplete`
--

DELIMITER $$
--
-- Procedures
--
CREATE PROCEDURE `GetCompletions` (IN `app_id` INT, IN `prefix_text` VARCHAR(255))  BEGIN
    IF (SELECT EXISTS (SELECT 1 FROM `prefixes` WHERE `prefix` = prefix_text)) THEN
        SELECT `completion` FROM `completions`
            WHERE `prefix_id` = (SELECT `id` FROM `prefixes` WHERE `app_id` = app_id AND `prefix` = prefix_text)
            ORDER BY `rank` DESC;
    END IF;
END$$

CREATE PROCEDURE `InsertCompletion` (IN `app_id` INT, IN `completion_text` VARCHAR(255), IN `max_prefixes` INT, IN `max_bucket_size` INT)  BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE prefix VARCHAR(255) DEFAULT '';
    DECLARE completion_length VARCHAR(255);
    SET completion_length = CHAR_LENGTH(completion_text);
    IF completion_length < max_prefixes THEN
        SET max_prefixes = completion_length;
    END IF;
    insertion_loop: LOOP
        IF i > max_prefixes THEN 
            LEAVE insertion_loop;
        END IF;
        SET prefix = CONCAT(prefix, SUBSTRING(completion_text, i, 1));
        INSERT INTO `prefixes` (`app_id`, `prefix`) VALUES (app_id, prefix)
            ON DUPLICATE KEY UPDATE `id` = LAST_INSERT_ID(`id`);
        SELECT LAST_INSERT_ID() INTO @prefix_id;
        IF (SELECT EXISTS (SELECT 1 FROM `completions`
            WHERE `prefix_id` = @prefix_id AND `completion` = completion_text)) THEN
            UPDATE `completions` SET `rank` = `rank` + 1
                WHERE `prefix_id` = @prefix_id AND `completion` = completion_text;
        ELSE
            SET @bucket_size = (SELECT COUNT(*) FROM `completions`
                WHERE `prefix_id` = @prefix_id);
            IF @bucket_size >= max_bucket_size THEN
                UPDATE `completions` SET `completion` = completion_text, `rank` = `rank` + 1
                    WHERE `id` = (SELECT id FROM `completions`
                        WHERE `prefix_id` = @prefix_id ORDER BY `rank` ASC LIMIT 1);
            ELSE
                INSERT INTO `completions` (`prefix_id`, `completion`, `rank`)
                    VALUES (@prefix_id, completion_text, 1);
            END IF;
        END IF;
        SET i = i + 1;
    END LOOP;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `apps`
--

CREATE TABLE `apps` (
  `id` int(11) NOT NULL,
  `app_key` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `completions`
--

CREATE TABLE `completions` (
  `id` int(11) NOT NULL,
  `prefix_id` int(11) NOT NULL,
  `completion` varchar(255) NOT NULL,
  `rank` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `prefixes`
--

CREATE TABLE `prefixes` (
  `id` int(11) NOT NULL,
  `app_id` int(11) NOT NULL,
  `prefix` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `apps`
--
ALTER TABLE `apps`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `app_key` (`app_key`) USING BTREE;

--
-- Indexes for table `completions`
--
ALTER TABLE `completions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `prefix_id-completion` (`prefix_id`,`completion`) USING BTREE,
  ADD KEY `prefix_id` (`prefix_id`) USING BTREE;

--
-- Indexes for table `prefixes`
--
ALTER TABLE `prefixes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `app_id-prefix` (`app_id`,`prefix`),
  ADD KEY `prefix` (`prefix`) USING BTREE;

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `apps`
--
ALTER TABLE `apps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `completions`
--
ALTER TABLE `completions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `prefixes`
--
ALTER TABLE `prefixes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
