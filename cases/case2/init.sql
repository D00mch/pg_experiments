CREATE TABLE global_counters (id INT PRIMARY KEY, cnt BIGINT);

INSERT INTO global_counters (id, cnt)
SELECT id, 1000000
FROM generate_series(1, 100) AS id;
