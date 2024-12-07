\set v_id random(1, 100)
\set v_delta random(-10, 10)

update global_counters set cnt = cnt + :v_delta where id = :v_id;
