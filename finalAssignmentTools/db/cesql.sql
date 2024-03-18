-- MySQL dump 10.13  Distrib 8.0.17, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: cesi
-- ------------------------------------------------------
-- Server version	8.0.17

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `appeal_management`
--

DROP TABLE IF EXISTS `appeal_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appeal_management` (
  `offense_id` int(11) DEFAULT NULL,
  `appellant_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_card_number` varchar(18) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `appeal_reason` text COLLATE utf8mb4_unicode_ci,
  `appeal_time` datetime DEFAULT NULL,
  `process_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `process_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  KEY `offense_id` (`offense_id`),
  CONSTRAINT `appeal_management_ibfk_1` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `appeal_management`
--

LOCK TABLES `appeal_management` WRITE;
/*!40000 ALTER TABLE `appeal_management` DISABLE KEYS */;
/*!40000 ALTER TABLE `appeal_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `backup_restore`
--

DROP TABLE IF EXISTS `backup_restore`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `backup_restore` (
  `backup_id` int(11) NOT NULL AUTO_INCREMENT,
  `backup_file_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `backup_time` datetime DEFAULT NULL,
  `restore_time` datetime DEFAULT NULL,
  `restore_status` enum('Success','Failed') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`backup_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `backup_restore`
--

LOCK TABLES `backup_restore` WRITE;
/*!40000 ALTER TABLE `backup_restore` DISABLE KEYS */;
/*!40000 ALTER TABLE `backup_restore` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `case_statistics`
--

DROP TABLE IF EXISTS `case_statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `case_statistics` (
  `offense_id` int(11) NOT NULL AUTO_INCREMENT,
  `offense_time` datetime DEFAULT NULL,
  `offense_location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license_plate` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driver_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `offense_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `offense_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fine_amount` decimal(10,2) DEFAULT NULL,
  `deducted_points` int(11) DEFAULT NULL,
  `process_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `process_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `case_statistics`
--

LOCK TABLES `case_statistics` WRITE;
/*!40000 ALTER TABLE `case_statistics` DISABLE KEYS */;
/*!40000 ALTER TABLE `case_statistics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deduction_information`
--

DROP TABLE IF EXISTS `deduction_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deduction_information` (
  `offense_id` int(11) DEFAULT NULL,
  `deducted_points` int(11) DEFAULT NULL,
  `deduction_time` datetime DEFAULT NULL,
  `handler` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approver` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  KEY `offense_id` (`offense_id`),
  CONSTRAINT `deduction_information_ibfk_1` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deduction_information`
--

LOCK TABLES `deduction_information` WRITE;
/*!40000 ALTER TABLE `deduction_information` DISABLE KEYS */;
/*!40000 ALTER TABLE `deduction_information` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `driver_information`
--

DROP TABLE IF EXISTS `driver_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_information` (
  `driver_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_card_number` varchar(18) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driver_license_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('Male','Female','Other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `first_license_date` date DEFAULT NULL,
  `allowed_vehicle_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  PRIMARY KEY (`driver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `driver_information`
--

LOCK TABLES `driver_information` WRITE;
/*!40000 ALTER TABLE `driver_information` DISABLE KEYS */;
/*!40000 ALTER TABLE `driver_information` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fine_information`
--

DROP TABLE IF EXISTS `fine_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fine_information` (
  `offense_id` int(11) DEFAULT NULL,
  `fine_amount` decimal(10,2) DEFAULT NULL,
  `fine_time` datetime DEFAULT NULL,
  `payee` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `account_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `receipt_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  KEY `offense_id` (`offense_id`),
  CONSTRAINT `fine_information_ibfk_1` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fine_information`
--

LOCK TABLES `fine_information` WRITE;
/*!40000 ALTER TABLE `fine_information` DISABLE KEYS */;
/*!40000 ALTER TABLE `fine_information` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login_log`
--

DROP TABLE IF EXISTS `login_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_log` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `login_ip_address` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `login_time` datetime DEFAULT NULL,
  `login_result` enum('Success','Failed') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `browser_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `os_version` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_log`
--

LOCK TABLES `login_log` WRITE;
/*!40000 ALTER TABLE `login_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `login_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `offense_appeal`
--

DROP TABLE IF EXISTS `offense_appeal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offense_appeal` (
  `offense_id` int(11) DEFAULT NULL,
  `appeal_id` int(11) DEFAULT NULL,
  KEY `offense_id` (`offense_id`),
  KEY `appeal_id` (`appeal_id`),
  CONSTRAINT `offense_appeal_ibfk_1` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`),
  CONSTRAINT `offense_appeal_ibfk_2` FOREIGN KEY (`appeal_id`) REFERENCES `appeal_management` (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `offense_appeal`
--

LOCK TABLES `offense_appeal` WRITE;
/*!40000 ALTER TABLE `offense_appeal` DISABLE KEYS */;
/*!40000 ALTER TABLE `offense_appeal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `offense_deduction`
--

DROP TABLE IF EXISTS `offense_deduction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offense_deduction` (
  `offense_id` int(11) DEFAULT NULL,
  `deduction_id` int(11) DEFAULT NULL,
  KEY `offense_id` (`offense_id`),
  KEY `deduction_id` (`deduction_id`),
  CONSTRAINT `offense_deduction_ibfk_1` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`),
  CONSTRAINT `offense_deduction_ibfk_2` FOREIGN KEY (`deduction_id`) REFERENCES `deduction_information` (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `offense_deduction`
--

LOCK TABLES `offense_deduction` WRITE;
/*!40000 ALTER TABLE `offense_deduction` DISABLE KEYS */;
/*!40000 ALTER TABLE `offense_deduction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `offense_fine`
--

DROP TABLE IF EXISTS `offense_fine`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offense_fine` (
  `offense_id` int(11) DEFAULT NULL,
  `fine_id` int(11) DEFAULT NULL,
  KEY `offense_id` (`offense_id`),
  KEY `fine_id` (`fine_id`),
  CONSTRAINT `offense_fine_ibfk_1` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`),
  CONSTRAINT `offense_fine_ibfk_2` FOREIGN KEY (`fine_id`) REFERENCES `fine_information` (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `offense_fine`
--

LOCK TABLES `offense_fine` WRITE;
/*!40000 ALTER TABLE `offense_fine` DISABLE KEYS */;
/*!40000 ALTER TABLE `offense_fine` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `offense_information`
--

DROP TABLE IF EXISTS `offense_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offense_information` (
  `offense_id` int(11) NOT NULL AUTO_INCREMENT,
  `offense_time` datetime DEFAULT NULL,
  `offense_location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license_plate` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driver_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `offense_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `offense_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fine_amount` decimal(10,2) DEFAULT NULL,
  `deducted_points` int(11) DEFAULT NULL,
  `process_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `process_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`offense_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `offense_information`
--

LOCK TABLES `offense_information` WRITE;
/*!40000 ALTER TABLE `offense_information` DISABLE KEYS */;
/*!40000 ALTER TABLE `offense_information` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation_log`
--

DROP TABLE IF EXISTS `operation_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operation_log` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `operation_time` datetime DEFAULT NULL,
  `operation_ip_address` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `operation_content` text COLLATE utf8mb4_unicode_ci,
  `operation_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`log_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `operation_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user_management` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation_log`
--

LOCK TABLES `operation_log` WRITE;
/*!40000 ALTER TABLE `operation_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permission_management`
--

DROP TABLE IF EXISTS `permission_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permission_management` (
  `permission_id` int(11) NOT NULL AUTO_INCREMENT,
  `permission_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `permission_description` text COLLATE utf8mb4_unicode_ci,
  `created_time` datetime DEFAULT NULL,
  `modified_time` datetime DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permission_management`
--

LOCK TABLES `permission_management` WRITE;
/*!40000 ALTER TABLE `permission_management` DISABLE KEYS */;
/*!40000 ALTER TABLE `permission_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_management`
--

DROP TABLE IF EXISTS `role_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_management` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `role_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role_description` text COLLATE utf8mb4_unicode_ci,
  `permission_list` text COLLATE utf8mb4_unicode_ci,
  `created_time` datetime DEFAULT NULL,
  `modified_time` datetime DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_management`
--

LOCK TABLES `role_management` WRITE;
/*!40000 ALTER TABLE `role_management` DISABLE KEYS */;
/*!40000 ALTER TABLE `role_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_permission`
--

DROP TABLE IF EXISTS `role_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permission` (
  `role_id` int(11) DEFAULT NULL,
  `permission_id` int(11) DEFAULT NULL,
  KEY `role_id` (`role_id`),
  KEY `permission_id` (`permission_id`),
  CONSTRAINT `role_permission_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `role_management` (`role_id`),
  CONSTRAINT `role_permission_ibfk_2` FOREIGN KEY (`permission_id`) REFERENCES `permission_management` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_permission`
--

LOCK TABLES `role_permission` WRITE;
/*!40000 ALTER TABLE `role_permission` DISABLE KEYS */;
/*!40000 ALTER TABLE `role_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `system_logs`
--

DROP TABLE IF EXISTS `system_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_logs` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `log_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `log_content` text COLLATE utf8mb4_unicode_ci,
  `operation_time` datetime DEFAULT NULL,
  `operation_user` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `operation_ip_address` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `system_logs`
--

LOCK TABLES `system_logs` WRITE;
/*!40000 ALTER TABLE `system_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `system_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `system_settings`
--

DROP TABLE IF EXISTS `system_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_settings` (
  `system_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `system_version` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `system_description` text COLLATE utf8mb4_unicode_ci,
  `copyright_info` text COLLATE utf8mb4_unicode_ci,
  `storage_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `login_timeout` int(11) DEFAULT NULL,
  `session_timeout` int(11) DEFAULT NULL,
  `date_format` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `page_size` int(11) DEFAULT NULL,
  `smtp_server` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_account` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_password` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `system_settings`
--

LOCK TABLES `system_settings` WRITE;
/*!40000 ALTER TABLE `system_settings` DISABLE KEYS */;
/*!40000 ALTER TABLE `system_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_management`
--

DROP TABLE IF EXISTS `user_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_management` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_type` enum('Admin','Operator') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('Active','Inactive') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_time` datetime DEFAULT NULL,
  `modified_time` datetime DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_management`
--

LOCK TABLES `user_management` WRITE;
/*!40000 ALTER TABLE `user_management` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_role` (
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  KEY `user_id` (`user_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `user_role_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user_management` (`user_id`),
  CONSTRAINT `user_role_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `role_management` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_role`
--

LOCK TABLES `user_role` WRITE;
/*!40000 ALTER TABLE `user_role` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vehicle_information`
--

DROP TABLE IF EXISTS `vehicle_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle_information` (
  `vehicle_id` int(11) NOT NULL AUTO_INCREMENT,
  `license_plate` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `owner_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_card_number` varchar(18) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `engine_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `frame_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_color` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_registration_date` date DEFAULT NULL,
  `current_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`vehicle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vehicle_information`
--

LOCK TABLES `vehicle_information` WRITE;
/*!40000 ALTER TABLE `vehicle_information` DISABLE KEYS */;
/*!40000 ALTER TABLE `vehicle_information` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-03-18 15:47:16
