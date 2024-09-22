CREATE TABLE publications (
    name VARCHAR(250) PRIMARY KEY,
    avatar VARCHAR(250)
);

CREATE TABLE reviewers (
    name VARCHAR(255),
    publication VARCHAR(250),
    avatar VARCHAR(250),
    PRIMARY KEY (name),
    FOREIGN KEY (publication) REFERENCES publications(name)
);

CREATE TABLE movies (
    title VARCHAR(250),
    release VARCHAR(250),
    score INT(11),
    reviewer VARCHAR(250),
    publication VARCHAR(250),
    PRIMARY KEY (title),
    FOREIGN KEY (reviewer) REFERENCES reviewers(name),
    FOREIGN KEY (publication) REFERENCES publications(name)
);

