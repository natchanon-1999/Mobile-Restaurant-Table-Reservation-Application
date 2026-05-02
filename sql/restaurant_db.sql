-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 01, 2026 at 12:24 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `restaurant_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerateReservationCode` (OUT `res_code` VARCHAR(20))   BEGIN
  DECLARE code VARCHAR(20);
  DECLARE done INT DEFAULT 0;
  REPEAT
    SET code = CONCAT('RES', DATE_FORMAT(NOW(),'%y%m'), LPAD(FLOOR(RAND()*99999), 5, '0'));
    SELECT COUNT(*) INTO done FROM reservations WHERE reservation_code = code;
  UNTIL done = 0 END REPEAT;
  SET res_code = code;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

CREATE TABLE `reservations` (
  `id` int(11) NOT NULL,
  `reservation_code` varchar(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `table_id` int(11) NOT NULL,
  `guest_count` int(11) NOT NULL DEFAULT 1,
  `reservation_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('pending','confirmed','cancelled','completed','no_show') NOT NULL DEFAULT 'pending',
  `special_request` text DEFAULT NULL,
  `occasion` enum('','birthday','anniversary','business','date','family') DEFAULT '',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `reservations`
--

INSERT INTO `reservations` (`id`, `reservation_code`, `user_id`, `table_id`, `guest_count`, `reservation_date`, `start_time`, `end_time`, `status`, `special_request`, `occasion`, `notes`, `created_at`, `updated_at`) VALUES
(2, 'RES260449786', 4, 1, 2, '2026-04-30', '19:00:00', '21:00:00', 'no_show', '', '', NULL, '2026-04-29 12:37:12', '2026-04-30 08:14:56'),
(3, 'RES260436366', 4, 1, 2, '2026-04-30', '19:00:00', '21:00:00', 'no_show', '', '', NULL, '2026-04-29 12:39:06', '2026-04-30 08:15:40'),
(4, 'RES260480812', 2, 1, 2, '2026-04-30', '07:00:00', '09:00:00', 'cancelled', '', 'birthday', NULL, '2026-04-30 08:12:47', '2026-04-30 08:15:39'),
(5, 'RES260418356', 2, 3, 2, '2026-04-30', '09:30:00', '11:30:00', 'no_show', '', '', NULL, '2026-04-30 08:14:07', '2026-04-30 08:15:45'),
(6, 'RES260439046', 2, 2, 2, '2026-04-30', '11:30:00', '13:30:00', 'cancelled', '', 'birthday', NULL, '2026-04-30 08:14:14', '2026-04-30 19:18:56'),
(7, 'RES260426657', 2, 4, 2, '2026-04-30', '09:30:00', '11:30:00', 'cancelled', '', 'family', NULL, '2026-04-30 08:14:25', '2026-04-30 19:18:58'),
(8, 'RES260473913', 2, 8, 2, '2026-04-30', '21:00:00', '23:00:00', 'no_show', '', 'date', NULL, '2026-04-30 08:14:33', '2026-04-30 08:14:52');

-- --------------------------------------------------------

--
-- Table structure for table `tables`
--

CREATE TABLE `tables` (
  `id` int(11) NOT NULL,
  `table_number` varchar(10) NOT NULL,
  `capacity` int(11) NOT NULL DEFAULT 2,
  `zone` enum('indoor','outdoor','vip','rooftop') NOT NULL DEFAULT 'indoor',
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tables`
--

INSERT INTO `tables` (`id`, `table_number`, `capacity`, `zone`, `description`, `image_url`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'T01', 2, 'indoor', 'โต๊ะริมหน้าต่าง วิวสวน', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499357777368322189/image.png?ex=69f4813e&is=69f32fbe&hm=74a44c9dc86e0104cce75b54b54888ced1379d7355edb680cb1a717dc7df5259&', 1, '2026-04-29 11:38:46', '2026-04-30 11:28:02'),
(2, 'T02', 2, 'indoor', 'โต๊ะส่วนตัว มุมเงียบ', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499357778060513392/image.png?ex=69f4813f&is=69f32fbf&hm=d1c45fbd3f3b3b8e367d271f54154fba0dc314c366e900a160151c6c778834e1&', 1, '2026-04-29 11:38:46', '2026-04-30 11:28:11'),
(3, 'T03', 4, 'indoor', 'โต๊ะกลางห้อง บรรยากาศดี', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499355110772310116/image.png?ex=69f47ec3&is=69f32d43&hm=73acee7fec5563f86236c5c81fdfbd5cce05149cfc326ba15267703745431739&', 1, '2026-04-29 11:38:46', '2026-04-30 19:09:58'),
(4, 'T04', 4, 'indoor', 'โต๊ะครอบครัว กว้างขวาง', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499366459892170874/image.png?ex=69f53214&is=69f3e094&hm=b914de6a6582f9e444daa0bed1c0c64f70c917fcfc370bf08ae737f39dc89be0&', 1, '2026-04-29 11:38:46', '2026-05-01 10:23:21'),
(5, 'T05', 6, 'indoor', 'โต๊ะกลุ่ม เหมาะสำหรับปาร์ตี้', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499357778655969290/image.png?ex=69f4813f&is=69f32fbf&hm=36489d5505e60f0a40be30ae94046d28f883f7b2400e192776ad2146a639d91e&', 1, '2026-04-29 11:38:46', '2026-04-30 11:28:26'),
(6, 'T06', 2, 'outdoor', 'โต๊ะกลางแจ้ง วิวสวนสวย', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499364750893776976/image.png?ex=69f487bd&is=69f3363d&hm=cc31095d1b211b96f76aae1f2deda23dc4b4080fe08fdee52a44cc21a9fef3b5&', 1, '2026-04-29 11:38:46', '2026-04-30 11:29:55'),
(7, 'T07', 4, 'outdoor', 'โต๊ะสวน ใต้ร่มไม้', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499364751409545286/image.png?ex=69f487bd&is=69f3363d&hm=b3cacd7d81a37f4efa3025be942160524f2a8ebc59caefe6118d146ed9eee6cc&', 1, '2026-04-29 11:38:46', '2026-04-30 11:30:02'),
(8, 'T08', 2, 'vip', 'VIP Room ส่วนตัว บริการพิเศษ', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499355110353141760/image.png?ex=69f47ec2&is=69f32d42&hm=60765449d5a4dbbe9e17c59b0e7993091e27e8aeb9e91e0a9d5e6a7949c276e4&', 1, '2026-04-29 11:38:46', '2026-04-30 11:30:12'),
(9, 'T09', 4, 'vip', 'VIP Suite พร้อมห้องประชุม', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499355110772310116/image.png?ex=69f47ec3&is=69f32d43&hm=73acee7fec5563f86236c5c81fdfbd5cce05149cfc326ba15267703745431739&', 1, '2026-04-29 11:38:46', '2026-04-30 11:30:18'),
(10, 'T10', 8, 'rooftop', 'Rooftop วิว 360 องศา', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499366460332703814/image.png?ex=69f53215&is=69f3e095&hm=ea47a2aff2789e1cf33b2712586ec8a46edf9c331c87bc3af3b21eedec2fe2d7&', 1, '2026-04-29 11:38:46', '2026-05-01 10:23:33'),
(11, 'T11', 4, 'rooftop', 'Rooftop โต๊ะกลางแจ้ง ชั้น 5', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499366459892170874/image.png?ex=69f48954&is=69f337d4&hm=49d6602b0880b0e976df6732c219f1ba8709cc357323819e3179aa4f6b093c13&', 1, '2026-04-29 11:38:46', '2026-04-30 11:30:50'),
(12, 'T12', 2, 'rooftop', 'Rooftop Couple Table วิวพระอาทิตย์ตก', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499366459489390633/image.png?ex=69f48954&is=69f337d4&hm=ea6c89013143e3a433e31e2e2114e2afcc6c85967ab93a02cf676df343801b69&', 1, '2026-04-29 11:38:46', '2026-04-30 11:30:39'),
(14, 'T13', 4, 'indoor', 'โต๊ะสำหรับครอบครัว', NULL, 0, '2026-04-29 12:41:26', '2026-04-29 12:42:07'),
(15, 'T14', 4, 'rooftop', '', 'https://cdn.discordapp.com/attachments/1496474925672956008/1499022140069122128/image.png?ex=69f3f168&is=69f29fe8&hm=3d5f795e442c1e95283ba8712b20efb58cf1e08a93720977097f27fd75267b94&', 0, '2026-04-30 09:47:23', '2026-04-30 09:47:52');

-- --------------------------------------------------------

--
-- Table structure for table `time_slots`
--

CREATE TABLE `time_slots` (
  `id` int(11) NOT NULL,
  `slot_name` varchar(50) NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `time_slots`
--

INSERT INTO `time_slots` (`id`, `slot_name`, `start_time`, `end_time`, `is_active`) VALUES
(1, 'Breakfast', '07:00:00', '09:00:00', 1),
(2, 'Brunch', '09:30:00', '11:30:00', 1),
(3, 'Lunch', '11:30:00', '13:30:00', 1),
(4, 'Afternoon', '14:00:00', '16:00:00', 1),
(5, 'Early Dinner', '17:00:00', '19:00:00', 1),
(6, 'Dinner', '19:00:00', '21:00:00', 1),
(7, 'Late Night', '21:00:00', '23:00:00', 1);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('customer','admin') NOT NULL DEFAULT 'customer',
  `avatar_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `password`, `role`, `avatar_url`, `created_at`, `updated_at`) VALUES
(1, 'Admin', 'admin@gmail.com', '0800000000', '1234', 'admin', NULL, '2026-04-29 11:38:46', '2026-04-29 11:42:11'),
(2, 'สมชาย ใจดี', 'user@gmail.com', '0812345678', '1234', 'customer', NULL, '2026-04-29 11:38:46', '2026-04-29 12:18:15'),
(4, 'oak kk', 'oak@gmail.com', '091239172', '$2y$10$8PhRJT37QkwskUqO51JW.ucSab/Abgp26dMTAnfQuGnw7fddRZsS6', 'customer', NULL, '2026-04-29 12:35:07', '2026-04-29 12:35:07');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_reservation_details`
-- (See below for the actual view)
--
CREATE TABLE `v_reservation_details` (
`id` int(11)
,`reservation_code` varchar(20)
,`guest_count` int(11)
,`reservation_date` date
,`start_time` time
,`end_time` time
,`status` enum('pending','confirmed','cancelled','completed','no_show')
,`special_request` text
,`occasion` enum('','birthday','anniversary','business','date','family')
,`notes` text
,`created_at` timestamp
,`user_id` int(11)
,`user_name` varchar(100)
,`user_email` varchar(150)
,`user_phone` varchar(20)
,`table_id` int(11)
,`table_number` varchar(10)
,`capacity` int(11)
,`zone` enum('indoor','outdoor','vip','rooftop')
,`table_description` text
);

-- --------------------------------------------------------

--
-- Structure for view `v_reservation_details`
--
DROP TABLE IF EXISTS `v_reservation_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_reservation_details`  AS SELECT `r`.`id` AS `id`, `r`.`reservation_code` AS `reservation_code`, `r`.`guest_count` AS `guest_count`, `r`.`reservation_date` AS `reservation_date`, `r`.`start_time` AS `start_time`, `r`.`end_time` AS `end_time`, `r`.`status` AS `status`, `r`.`special_request` AS `special_request`, `r`.`occasion` AS `occasion`, `r`.`notes` AS `notes`, `r`.`created_at` AS `created_at`, `u`.`id` AS `user_id`, `u`.`name` AS `user_name`, `u`.`email` AS `user_email`, `u`.`phone` AS `user_phone`, `t`.`id` AS `table_id`, `t`.`table_number` AS `table_number`, `t`.`capacity` AS `capacity`, `t`.`zone` AS `zone`, `t`.`description` AS `table_description` FROM ((`reservations` `r` join `users` `u` on(`r`.`user_id` = `u`.`id`)) join `tables` `t` on(`r`.`table_id` = `t`.`id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reservation_code` (`reservation_code`),
  ADD KEY `idx_res_date` (`reservation_date`),
  ADD KEY `idx_res_table` (`table_id`),
  ADD KEY `idx_res_user` (`user_id`),
  ADD KEY `idx_res_status` (`status`),
  ADD KEY `idx_res_code` (`reservation_code`);

--
-- Indexes for table `tables`
--
ALTER TABLE `tables`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `table_number` (`table_number`);

--
-- Indexes for table `time_slots`
--
ALTER TABLE `time_slots`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tables`
--
ALTER TABLE `tables`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `time_slots`
--
ALTER TABLE `time_slots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `reservations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reservations_ibfk_2` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
