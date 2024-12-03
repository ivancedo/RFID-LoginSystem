-- MySQL Dump 10.13  Distrib 8.0.40, for Win64 (x86_64)
-- 
-- Host: 192.168.1.1    Database: pbe
-- ------------------------------------------------------
-- Server Version: 8.0.40
-- 
-- Description: This SQL script initializes the database structure and populates initial data.

-- Set up configurations
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- ------------------------------------------------------
-- Table structure for `marks`
-- ------------------------------------------------------

DROP TABLE IF EXISTS `marks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;

CREATE TABLE `marks` (
  `id_marks` INT NOT NULL AUTO_INCREMENT,
  `student_id` VARCHAR(45) NOT NULL,
  `Subject` VARCHAR(45) DEFAULT NULL,
  `Name` VARCHAR(45) DEFAULT NULL,
  `Marks` FLOAT DEFAULT NULL,
  PRIMARY KEY (`id_marks`),
  KEY `idx_student_id` (`student_id`) /*!80000 INVISIBLE */,
  CONSTRAINT `student_id_marks` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data into `marks`
LOCK TABLES `marks` WRITE;
/*!40000 ALTER TABLE `marks` DISABLE KEYS */;
INSERT INTO `marks` VALUES 
(1, '060FFBB0', 'PBE', 'Puzzle1', 8.5),
(2, '060FFBB0', 'PBE', 'Puzzle2', 7.85),
-- Add additional rows as needed
(85, 'F632A914', 'PBE', 'Final', 7.6);
/*!40000 ALTER TABLE `marks` ENABLE KEYS */;
UNLOCK TABLES;

-- ------------------------------------------------------
-- Table structure for `students`
-- ------------------------------------------------------

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;

CREATE TABLE `students` (
  `name` VARCHAR(45) NOT NULL,
  `student_id` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`student_id`),
  UNIQUE KEY `student_id_UNIQUE` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data into `students`
LOCK TABLES `students` WRITE;
/*!40000 ALTER TABLE `students` DISABLE KEYS */;
INSERT INTO `students` VALUES 
('Ivan Cedo Marco', '060FFBB0'),
('Oscar Parada Fernandez', '13B67606'),
-- Add additional rows as needed
('Vicenc Parera Munoz', 'F632A914');
/*!40000 ALTER TABLE `students` ENABLE KEYS */;
UNLOCK TABLES;

-- ------------------------------------------------------
-- Table structure for `tasks`
-- ------------------------------------------------------

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;

CREATE TABLE `tasks` (
  `id_tasks` INT NOT NULL AUTO_INCREMENT,
  `student_id` VARCHAR(45) NOT NULL,
  `date` DATE DEFAULT NULL,
  `subject` VARCHAR(45) NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id_tasks`),
  KEY `idxm_student_id` (`student_id`),
  CONSTRAINT `fk_tasks_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data into `tasks`
LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
INSERT INTO `tasks` VALUES 
(1, '060FFBB0', '2024-12-03', 'PBE', 'Critical Design Review'),
-- Add additional rows as needed
(22, 'F632A914', '2024-12-02', 'DSBM', 'Practica 4');
/*!40000 ALTER TABLE `tasks` ENABLE KEYS */;
UNLOCK TABLES;

-- ------------------------------------------------------
-- Table structure for `timetables`
-- ------------------------------------------------------

DROP TABLE IF EXISTS `timetables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;

CREATE TABLE `timetables` (
  `id_timetable` INT NOT NULL AUTO_INCREMENT,
  `student_id` VARCHAR(45) NOT NULL,
  `day` VARCHAR(45) DEFAULT NULL,
  `hour` TIME DEFAULT NULL,
  `Subject` VARCHAR(45) DEFAULT NULL,
  `Room` VARCHAR(45) DEFAULT NULL,
  PRIMARY KEY (`id_timetable`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `student_id` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=266 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data into `timetables`
LOCK TABLES `timetables` WRITE;
/*!40000 ALTER TABLE `timetables` DISABLE KEYS */;
INSERT INTO `timetables` VALUES 
(206, '060FFBB0', 'Mon', '14:00:00', 'EM', 'A3002'),
-- Add additional rows as needed
(265, 'F632A914', 'Fri', '18:00:00', 'LAB DSBM', 'C5S101A');
/*!40000 ALTER TABLE `timetables` ENABLE KEYS */;
UNLOCK TABLES;

-- Restore configurations
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- End of Script
