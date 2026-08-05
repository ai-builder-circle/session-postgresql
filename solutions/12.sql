-- Module 12 solutions: freelancer_skills many-to-many
BEGIN;
CREATE TABLE skills (
    id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE
);
CREATE TABLE freelancer_skills (
    freelancer_id bigint NOT NULL REFERENCES freelancers(id) ON DELETE CASCADE,
    skill_id      bigint NOT NULL REFERENCES skills(id)      ON DELETE CASCADE,
    PRIMARY KEY (freelancer_id, skill_id)     -- composite PK: each pair once
);
INSERT INTO skills (name) VALUES ('Branding'),('Frontend'),('UX'),('Copywriting');
-- assign skills
INSERT INTO freelancer_skills (freelancer_id, skill_id) VALUES
 (1,1),(1,2),(2,2),(2,3),(3,1),(4,4),(5,3),(5,1);
CREATE INDEX idx_fs_skill ON freelancer_skills(skill_id);  -- speeds "who has skill X" lookups
COMMIT;

-- 4 available freelancers per skill, ranked
SELECT s.name, count(*) FILTER (WHERE f.is_available) AS available_freelancers
FROM skills s
JOIN freelancer_skills fs ON fs.skill_id=s.id
JOIN freelancers f ON f.id=fs.freelancer_id
GROUP BY s.name ORDER BY available_freelancers DESC, s.name;

-- 5 within each skill, rank freelancers by rate
SELECT s.name, f.full_name, f.hourly_rate,
       rank() OVER (PARTITION BY s.id ORDER BY f.hourly_rate DESC) AS rate_rank
FROM skills s
JOIN freelancer_skills fs ON fs.skill_id=s.id
JOIN freelancers f ON f.id=fs.freelancer_id
ORDER BY s.name, rate_rank;

-- 6 justify the index
EXPLAIN ANALYZE SELECT freelancer_id FROM freelancer_skills WHERE skill_id=1;
