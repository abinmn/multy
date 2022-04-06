CREATE DATABASE IF NOT EXISTS multydb;

USE multydb;

# DROP TABLE IF EXISTS ApiKeys;
CREATE TABLE IF NOT EXISTS ApiKeys (
    ApiKey CHAR(64),
    UserId INT,
    PRIMARY KEY (ApiKey)
);

# DROP TABLE IF EXISTS Users;
CREATE TABLE IF NOT EXISTS Users (
    UserId INT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (UserId)
);

# DROP TABLE IF EXISTS Locks;
CREATE TABLE IF NOT EXISTS Locks (
    UserId INT NOT NULL,
    LockId CHAR(64) NOT NULL,
    LockExpirationTimestamp TIMESTAMP,
    PRIMARY KEY (UserId, LockId)
)