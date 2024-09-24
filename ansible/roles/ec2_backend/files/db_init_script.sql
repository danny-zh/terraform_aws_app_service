create database if not exists movie_db;
use movie_db;

CREATE TABLE if not exists publications (
    name VARCHAR(250) PRIMARY KEY,
    avatar VARCHAR(250)
);

CREATE TABLE if not exists reviewers (
    name VARCHAR(255),
    publication VARCHAR(250),
    avatar VARCHAR(250),
    PRIMARY KEY (name),
    FOREIGN KEY (publication) REFERENCES publications(name)
);

CREATE TABLE if not exists movies (
    title VARCHAR(250),
    release_year VARCHAR(250),
    score INT(11),
    reviewer VARCHAR(250),
    publication VARCHAR(250),
    PRIMARY KEY (title),
    FOREIGN KEY (reviewer) REFERENCES reviewers(name),
    FOREIGN KEY (publication) REFERENCES publications(name)
);