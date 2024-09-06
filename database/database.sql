CREATE DATABASE IF NOT EXISTS notes_webapp;

USE notes_webapp;

CREATE TABLE IF NOT EXISTS note (
    id INT NOT NULL AUTO_INCREMENT,
    content TEXT,
    PRIMARY KEY (id)
);

