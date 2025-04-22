-- MySQL dump 10.13  Distrib 8.0.39, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: cesi
-- ------------------------------------------------------
-- Server version	8.0.39

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
  `appeal_id` int NOT NULL AUTO_INCREMENT,
  `offense_id` int NOT NULL,
  `appellant_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_card_number` varchar(18) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `appeal_reason` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `appeal_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `process_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Pending',
  `process_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`appeal_id`),
  KEY `idx_appeal_offense` (`offense_id`),
  CONSTRAINT `fk_appeal_offense` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`) ON DELETE CASCADE
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
  `backup_id` int NOT NULL AUTO_INCREMENT,
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
-- Table structure for table `deduction_information`
--

DROP TABLE IF EXISTS `deduction_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deduction_information` (
  `deduction_id` int NOT NULL AUTO_INCREMENT,
  `offense_id` int NOT NULL,
  `deducted_points` int DEFAULT '0',
  `deduction_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `handler` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `approver` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`deduction_id`),
  KEY `idx_deduction_offense` (`offense_id`),
  CONSTRAINT `fk_deduction_offense` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`) ON DELETE CASCADE
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
  `driver_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_card_number` varchar(18) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driver_license_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('Male','Female','Other') COLLATE utf8mb4_unicode_ci DEFAULT 'Other',
  `birthdate` date DEFAULT NULL,
  `first_license_date` date DEFAULT NULL,
  `allowed_vehicle_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  PRIMARY KEY (`driver_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `driver_information`
--

LOCK TABLES `driver_information` WRITE;
/*!40000 ALTER TABLE `driver_information` DISABLE KEYS */;
INSERT INTO `driver_information` VALUES (1,'黄广龙','1234567891234561','12345678912',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(2,'hgl@admin.com','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(3,'999@999.com','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(4,'\"hi\"','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(5,'\"黄秋传\"','\"1324648941961881\"','\"1556489841\"',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(6,'hqc@admin.com','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(7,'hglhgl@admin.com','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(8,'黄广龙','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(9,'黄广龙','','',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(10,'红双喜','78945612378945612','12385274112',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(11,'875@875.com','','12385274112',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(12,'红双喜','','12385274112',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(13,'红双喜','78945612378945612','12385274112',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(14,'悟理','1234567891234561','12345678912',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(15,'悟道','1234567891234561','12345678912',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(16,'黄广龙','1234567891234561','12345678912',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(17,'黄广','1234567891234561','12345678912',NULL,'Other',NULL,NULL,NULL,NULL,NULL),(18,'黄广龙','1234567891234561','12345678912',NULL,'Other',NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `driver_information` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fine_information`
--

DROP TABLE IF EXISTS `fine_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fine_information` (
  `fine_id` int NOT NULL AUTO_INCREMENT,
  `offense_id` int NOT NULL,
  `fine_amount` decimal(10,2) DEFAULT '0.00',
  `fine_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `payee` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `account_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `receipt_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`fine_id`),
  KEY `idx_fine_offense` (`offense_id`),
  CONSTRAINT `fk_fine_offense` FOREIGN KEY (`offense_id`) REFERENCES `offense_information` (`offense_id`) ON DELETE CASCADE
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
  `log_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `login_ip_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT 'unknown',
  `login_time` datetime NOT NULL,
  `login_result` enum('Success','Failed') COLLATE utf8mb4_unicode_ci NOT NULL,
  `browser_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `os_version` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_log`
--

LOCK TABLES `login_log` WRITE;
/*!40000 ALTER TABLE `login_log` DISABLE KEYS */;
INSERT INTO `login_log` VALUES (7,'hgl@hgl.com','unknown','2025-03-07 08:52:34','Failed',NULL,NULL,NULL),(8,'hgl@hgl.com','unknown','2025-03-07 20:38:13','Failed',NULL,NULL,NULL),(9,'hgl@hgl.com','unknown','2025-03-08 08:03:42','Failed',NULL,NULL,NULL),(10,'hgl@hgl.com','unknown','2025-03-08 08:49:57','Failed',NULL,NULL,NULL),(11,'hgl@hgl.com','unknown','2025-03-08 08:50:39','Failed',NULL,NULL,NULL),(12,'hgl@hgl.com','unknown','2025-03-08 09:09:18','Failed',NULL,NULL,NULL),(13,'hgl@admin.com','unknown','2025-03-08 09:16:13','Failed',NULL,NULL,NULL),(14,'hgl@hgl.com','unknown','2025-03-08 10:42:47','Failed',NULL,NULL,NULL),(15,'hgl@hgl.com','unknown','2025-03-08 14:12:03','Failed',NULL,NULL,NULL),(16,'hgl@hgl.com','unknown','2025-03-10 02:16:53','Failed',NULL,NULL,NULL),(17,'hgl@hgl.com','unknown','2025-03-10 02:17:03','Failed',NULL,NULL,NULL),(18,'hgl@hgl.com','unknown','2025-03-11 23:49:26','Failed',NULL,NULL,NULL),(19,'hgl@hgl.com','unknown','2025-03-11 23:56:42','Failed',NULL,NULL,NULL),(20,'hgl@hgl.com','unknown','2025-03-12 16:44:01','Failed',NULL,NULL,NULL),(21,'985@985.com','unknown','2025-03-12 17:48:42','Failed',NULL,NULL,NULL),(22,'hgl@hgl.com','unknown','2025-03-14 15:06:41','Failed',NULL,NULL,NULL),(23,'hgl@hgl.com','unknown','2025-03-19 12:42:44','Failed',NULL,NULL,NULL),(24,'hgl@hgl.com','unknown','2025-03-19 15:15:49','Failed',NULL,NULL,NULL),(25,'hgl@hgl.com','unknown','2025-03-22 15:07:40','Failed',NULL,NULL,NULL),(26,'hgl@hgl.com','unknown','2025-03-28 09:45:59','Failed',NULL,NULL,NULL),(27,'hgl@hgl.com`','unknown','2025-03-28 10:25:55','Failed',NULL,NULL,NULL),(28,'hgl@hgl.com`','unknown','2025-03-28 10:26:05','Failed',NULL,NULL,NULL),(29,'hgl@hgl.com','unknown','2025-03-30 12:31:29','Failed',NULL,NULL,NULL),(30,'hgl@admin.com','unknown','2025-03-31 16:40:33','Failed',NULL,NULL,NULL),(31,'hgl@admin.com','unknown','2025-04-09 21:31:35','Failed',NULL,NULL,NULL),(32,'hgl@amdin.com','unknown','2025-04-10 20:37:57','Failed',NULL,NULL,NULL),(33,'hgl@amdin.com','unknown','2025-04-10 20:38:08','Failed',NULL,NULL,NULL),(34,'hgl@admin.com','unknown','2025-04-13 21:38:41','Failed',NULL,NULL,NULL);
/*!40000 ALTER TABLE `login_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `offense_details`
--

DROP TABLE IF EXISTS `offense_details`;
/*!50001 DROP VIEW IF EXISTS `offense_details`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `offense_details` AS SELECT 
 1 AS `offense_id`,
 1 AS `offense_time`,
 1 AS `offense_location`,
 1 AS `offense_type`,
 1 AS `offense_code`,
 1 AS `driver_name`,
 1 AS `driver_id_card_number`,
 1 AS `license_plate`,
 1 AS `vehicle_type`,
 1 AS `owner_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `offense_information`
--

DROP TABLE IF EXISTS `offense_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offense_information` (
  `offense_id` int NOT NULL AUTO_INCREMENT,
  `offense_time` datetime NOT NULL,
  `offense_location` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `license_plate` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `driver_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `offense_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `offense_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fine_amount` decimal(10,2) DEFAULT '0.00',
  `deducted_points` int DEFAULT '0',
  `process_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Unprocessed',
  `process_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driver_id` int DEFAULT NULL,
  `vehicle_id` int DEFAULT NULL,
  PRIMARY KEY (`offense_id`),
  KEY `idx_offense_time` (`offense_time`),
  KEY `idx_offense_driver` (`driver_id`),
  KEY `idx_offense_vehicle` (`vehicle_id`),
  CONSTRAINT `fk_offense_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle_information` (`vehicle_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
  `log_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `operation_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `operation_ip_address` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation_content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation_result` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`log_id`),
  KEY `fk_op_user` (`user_id`),
  CONSTRAINT `fk_op_user` FOREIGN KEY (`user_id`) REFERENCES `user_management` (`user_id`) ON DELETE CASCADE
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
  `permission_id` int NOT NULL AUTO_INCREMENT,
  `permission_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `permission_description` text COLLATE utf8mb4_unicode_ci,
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
-- Table structure for table `progress_items`
--

DROP TABLE IF EXISTS `progress_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `progress_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `submit_time` datetime NOT NULL,
  `details` text COLLATE utf8mb4_unicode_ci,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_username` (`username`),
  CONSTRAINT `chk_status` CHECK ((`status` in (_utf8mb4'Pending',_utf8mb4'Processing',_utf8mb4'Completed',_utf8mb4'Archived')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `progress_items`
--

LOCK TABLES `progress_items` WRITE;
/*!40000 ALTER TABLE `progress_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `progress_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `request_history`
--

DROP TABLE IF EXISTS `request_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `request_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `idempotency_key` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `business_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `business_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_idempotency_key` (`idempotency_key`)
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `request_history`
--

LOCK TABLES `request_history` WRITE;
/*!40000 ALTER TABLE `request_history` DISABLE KEYS */;
INSERT INTO `request_history` VALUES (46,'1741316308120,1741316308120','2025-03-07 02:58:28','SUCCESS',1),(47,'1741316584976,1741316584976','2025-03-07 03:03:04','SUCCESS',1),(48,'1741318422364,1741318422364','2025-03-07 03:33:42','SUCCESS',1),(49,'1741318450236,1741318450236','2025-03-07 03:34:10','SUCCESS',1),(50,'1741318466012,1741318466012','2025-03-07 03:34:26','SUCCESS',1),(51,'1741318932104,1741318932104','2025-03-07 03:42:13','SUCCESS',1),(52,'1741321606917,1741321606917','2025-03-07 04:26:46','SUCCESS',NULL),(53,'1741386809846,1741386809846','2025-03-07 22:33:29','SUCCESS',NULL),(54,'1741388926538,1741388926538','2025-03-07 23:08:46','SUCCESS',NULL),(55,'1741392268656,1741392268656','2025-03-08 00:04:28','SUCCESS',NULL),(56,'1741394815629,1741394815629','2025-03-08 00:46:57','SUCCESS',3),(57,'1741401811217,1741401811217','2025-03-08 02:43:31','SUCCESS',NULL),(58,'1741403305584,1741403305584','2025-03-08 03:08:25','SUCCESS',NULL),(59,'1741403504110,1741403504110','2025-03-08 03:11:44','SUCCESS',NULL),(60,'1741403966567,1741403966567','2025-03-08 03:19:26','SUCCESS',NULL),(61,'1741403975204,1741403975204','2025-03-08 03:19:35','SUCCESS',4),(62,'1741403984963,1741403984963','2025-03-08 03:19:44','SUCCESS',4),(63,'1741404025876,1741404025876','2025-03-08 03:20:25','SUCCESS',NULL),(64,'1741404104708,1741404104708','2025-03-08 03:21:44','SUCCESS',NULL),(65,'1741414615077,1741414615077','2025-03-08 06:16:55','SUCCESS',NULL),(66,'1741414639917,1741414639917','2025-03-08 06:17:19','SUCCESS',5),(67,'1741414655461,1741414655461','2025-03-08 06:17:35','SUCCESS',5),(68,'1741414663629,1741414663629','2025-03-08 06:17:43','SUCCESS',5),(69,'1741414881508,1741414881508','2025-03-08 06:21:21','SUCCESS',NULL),(70,'1741416161423,1741416161423','2025-03-08 06:42:41','SUCCESS',1),(71,'1741416273441,1741416273441','2025-03-08 06:44:33','SUCCESS',1),(72,'1741416371926,1741416371926','2025-03-08 06:46:11','SUCCESS',NULL),(73,'1741675735222,1741675735222','2025-03-11 06:48:55','SUCCESS',1),(74,'1741691747195,1741691747195','2025-03-11 11:15:47','SUCCESS',1),(75,'1741691941933,1741691941933','2025-03-11 11:19:01','SUCCESS',1),(76,'1741691950809,1741691950809','2025-03-11 11:19:10','SUCCESS',1),(77,'1741692657387,1741692657387','2025-03-11 11:30:57','SUCCESS',1),(78,'1741694925504,1741694925504','2025-03-11 12:08:45','SUCCESS',1),(79,'1741695474364,1741695474364','2025-03-11 12:17:54','SUCCESS',1),(80,'1741697910472,1741697910472','2025-03-11 12:58:30','SUCCESS',NULL),(81,'1741706081114,1741706081114','2025-03-11 15:14:41','SUCCESS',8),(82,'1741706443957,1741706443957','2025-03-11 15:20:44','SUCCESS',10),(83,'1741706470118,1741706470118','2025-03-11 15:21:10','SUCCESS',10),(84,'1741706503741,1741706503741','2025-03-11 15:21:43','SUCCESS',10),(85,'1741708156293,1741708156293','2025-03-11 15:49:16','SUCCESS',10),(86,'1741766292310,1741766292310','2025-03-12 07:58:12','SUCCESS',1),(87,'1741772916130,1741772916130','2025-03-12 09:48:36','SUCCESS',1),(88,'1741774095792,1741774095792','2025-03-12 10:08:15','SUCCESS',1),(89,'1741787849685,1741787849685','2025-03-12 13:57:29','SUCCESS',1),(90,'1742214347912,1742214347912','2025-03-17 12:25:48','SUCCESS',1),(91,'1742219346592,1742219346592','2025-03-17 13:49:06','SUCCESS',NULL),(92,'1742278901613,1742278901613','2025-03-18 06:21:41','SUCCESS',NULL),(93,'1742281655661,1742281655661','2025-03-18 07:07:35','SUCCESS',NULL),(94,'1742293682000','2025-03-18 10:28:02','SUCCESS',NULL),(95,'1742294238637','2025-03-18 10:37:18','SUCCESS',NULL),(96,'1742294739574','2025-03-18 10:45:39','SUCCESS',NULL),(97,'1742298706516','2025-03-18 11:51:46','SUCCESS',NULL),(98,'1742369213687','2025-03-19 07:26:53','SUCCESS',8),(99,'1742653671169','2025-03-22 14:27:51','SUCCESS',NULL),(100,'1742655106208','2025-03-22 14:51:46','SUCCESS',NULL),(101,'1742655565467','2025-03-22 14:59:25','SUCCESS',NULL),(102,'1742655986992','2025-03-22 15:06:27','SUCCESS',NULL),(103,'1742656774934','2025-03-22 15:19:34','SUCCESS',NULL),(104,'1745163725385','2025-04-20 15:42:05','SUCCESS',1),(105,'1745163849036','2025-04-20 15:44:09','SUCCESS',NULL),(106,'1745163916151','2025-04-20 15:45:16','SUCCESS',1);
/*!40000 ALTER TABLE `request_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_management`
--

DROP TABLE IF EXISTS `role_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_management` (
  `role_id` int NOT NULL AUTO_INCREMENT,
  `role_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role_description` text COLLATE utf8mb4_unicode_ci,
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_management`
--

LOCK TABLES `role_management` WRITE;
/*!40000 ALTER TABLE `role_management` DISABLE KEYS */;
INSERT INTO `role_management` VALUES (3,'USER','普通用户角色','2025-03-07 10:57:55','2025-03-07 10:57:55',NULL),(4,'ADMIN','管理员角色','2025-03-07 12:26:42','2025-03-07 12:26:41',NULL);
/*!40000 ALTER TABLE `role_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_permission`
--

DROP TABLE IF EXISTS `role_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permission` (
  `role_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`role_id`,`permission_id`),
  KEY `fk_rp_permission` (`permission_id`),
  CONSTRAINT `fk_rp_permission` FOREIGN KEY (`permission_id`) REFERENCES `permission_management` (`permission_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `role_management` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
  `log_id` int NOT NULL AUTO_INCREMENT,
  `log_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `log_content` text COLLATE utf8mb4_unicode_ci,
  `operation_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `operation_user` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation_ip_address` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
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
  `system_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `system_version` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `system_description` text COLLATE utf8mb4_unicode_ci,
  `copyright_info` text COLLATE utf8mb4_unicode_ci,
  `storage_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `login_timeout` int DEFAULT NULL,
  `session_timeout` int DEFAULT NULL,
  `date_format` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `page_size` int DEFAULT NULL,
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
  `user_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('Active','Inactive') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_management`
--

LOCK TABLES `user_management` WRITE;
/*!40000 ALTER TABLE `user_management` DISABLE KEYS */;
INSERT INTO `user_management` VALUES (1,'hgl@hgl.com','741852',NULL,NULL,'Active','2025-03-07 11:03:00','2025-03-11 20:17:55',NULL),(2,'hgl@admin.com','123456',NULL,NULL,'Active','2025-03-07 12:26:42','2025-03-07 12:26:41',NULL),(3,'999@999.com','123456',NULL,NULL,'Active','2025-03-08 08:04:24','2025-03-08 08:04:24',NULL),(4,'hi@hi.com','123456',NULL,NULL,'Active','2025-03-08 11:17:39','2025-03-08 11:17:39',NULL),(5,'hqc@hqc.com','123456',NULL,NULL,'Active','2025-03-08 14:15:09','2025-03-08 14:15:08',NULL),(6,'hqc@admin.com','123456',NULL,NULL,'Active','2025-03-08 14:19:07','2025-03-08 14:19:06',NULL),(7,'hglhgl@admin.com','123456',NULL,NULL,'Active','2025-03-08 14:46:00','2025-03-08 14:46:00',NULL),(8,'985@985.com','123456',NULL,NULL,'Active','2025-03-11 22:11:32','2025-03-11 22:11:31',NULL),(9,'15684@15684.com','123456',NULL,NULL,'Active','2025-03-11 22:17:58','2025-03-11 22:17:58',NULL),(10,'875@875.com','741852',NULL,NULL,'Active','2025-03-11 23:20:27','2025-03-11 23:20:26',NULL),(11,'cwe@cwe.com','741822',NULL,NULL,'Active','2025-03-18 15:12:25','2025-03-18 15:12:24',NULL);
/*!40000 ALTER TABLE `user_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_role` (
  `user_id` int NOT NULL,
  `role_id` int NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `fk_ur_role` (`role_id`),
  CONSTRAINT `fk_ur_role` FOREIGN KEY (`role_id`) REFERENCES `role_management` (`role_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ur_user` FOREIGN KEY (`user_id`) REFERENCES `user_management` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_role`
--

LOCK TABLES `user_role` WRITE;
/*!40000 ALTER TABLE `user_role` DISABLE KEYS */;
INSERT INTO `user_role` VALUES (1,3),(3,3),(4,3),(5,3),(8,3),(9,3),(10,3),(11,3),(2,4),(6,4),(7,4);
/*!40000 ALTER TABLE `user_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vehicle_information`
--

DROP TABLE IF EXISTS `vehicle_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle_information` (
  `vehicle_id` int NOT NULL AUTO_INCREMENT,
  `license_plate` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vehicle_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_card_number` varchar(18) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `engine_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `frame_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_color` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_registration_date` date DEFAULT NULL,
  `current_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Active',
  PRIMARY KEY (`vehicle_id`),
  UNIQUE KEY `unique_license_plate` (`license_plate`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vehicle_information`
--

LOCK TABLES `vehicle_information` WRITE;
/*!40000 ALTER TABLE `vehicle_information` DISABLE KEYS */;
INSERT INTO `vehicle_information` VALUES (5,'7854','1564','294色','1472583691472587','12345678912','1234','154','色','2025-03-08','色'),(8,'黑AD765','本田','黄广龙','1234567891234561','12345678912','148945984','1894351','白','2025-03-17','Active'),(9,'黑AE863','丰田','hgl@hgl.com','1234567891234561','12345678912','156486','3487','黑色','2025-03-18','Active'),(10,'黑AD5E1','雷克萨斯','hgl@hgl.com','1234567891234561','12345678912','489616','18968','黑','2025-03-18','Active'),(11,'黑ADDDD','se','hgl@hgl.com','1234567891234561','12345678912','4891','48949','564','2025-03-18','Active'),(12,'黑AD3EE1','se','hgl@hgl.com','1234567891234561','12345678912','184632649','296849','白','2025-03-18','Active'),(13,'黑ASEb','se','hgl@hgl.com','1234567891234561','12345678912','sfavagrv','ssadfvasrg','sergfv','2025-03-18','Active'),(16,'黑AD6E5','丰田','hgl@hgl.com','1234567891234561','12345678912','489171','751781','白','2025-03-22','Active'),(17,'黑AB323','丰田','hgl@hgl.com','1234567891234561','12345678912','48544416167','3221184','黑','2025-03-22','Active'),(18,'黑AC3A4','奔驰','hgl@hgl.com','1234567891234561','12345678912','15641831','54145616','黑','2025-03-22','Active'),(19,'黑AG3G4','宝马','hgl@hgl.com','1234567891234561','12345678912','16441564','4596198414','黑','2025-03-22','Active'),(20,'黑AWS34','奔驰','黄广龙','1234567891234561','12345678912','16455648523','1854561654','黑','2025-03-22','Active');
/*!40000 ALTER TABLE `vehicle_information` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `offense_details`
--

/*!50001 DROP VIEW IF EXISTS `offense_details`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=MERGE */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `offense_details` AS select `o`.`offense_id` AS `offense_id`,`o`.`offense_time` AS `offense_time`,`o`.`offense_location` AS `offense_location`,`o`.`offense_type` AS `offense_type`,`o`.`offense_code` AS `offense_code`,`d`.`name` AS `driver_name`,`d`.`id_card_number` AS `driver_id_card_number`,`v`.`license_plate` AS `license_plate`,`v`.`vehicle_type` AS `vehicle_type`,`v`.`owner_name` AS `owner_name` from ((`offense_information` `o` left join `driver_information` `d` on((`o`.`driver_id` = `d`.`driver_id`))) left join `vehicle_information` `v` on((`o`.`vehicle_id` = `v`.`vehicle_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-04-22 21:47:50
