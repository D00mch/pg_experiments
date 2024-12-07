Based on the [article]()

# Example 1

## Setup

```sql
create table shopping (
        customerid bigint, categoryid bigint, weekday text, total money
);

insert into shopping (customerid, categoryid, weekday, total)
        select random()*1e6, random()*100, 'day ' || (random()*7)::integer,
                random()*1000::money
        from generate_series(1,1e6) as gs;

vacuum analyze shopping;

set work_mem = '256mb';
```

Below we will sort by `customerid` first and by `weekday` first. The `weekday` sort performance worse because there are only 7 days in the week, so sorting has to get the next column to compare equal weekdays.   

Why do we care? When we use `group by`, sorting order doesn't matter, any order is ok.

## Sort with the same select order


```sql
explain (analyze, buffers)
select customerid, categoryid, weekday, total
from shopping
order by customerid, categoryid, weekday, total;

    │ QUERY PLAN
────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1 │ Sort  (cost=140936.84..143436.84 rows=1000000 width=30) (actual time=409.852..496.029 rows=1000000 loops=1)
  2 │   Sort Key: customerid, categoryid, weekday, total
  3 │   Sort Method: external merge  Disk: 41160kB
  4 │   Buffers: shared hit=7364, temp read=10283 written=10306
  5 │   ->  Seq Scan on shopping  (cost=0.00..17353.00 rows=1000000 width=30) (actual time=0.039..70.018 rows=1000000 loops=1)
  6 │         Buffers: shared hit=7353
  7 │ Planning:
  8 │   Buffers: shared hit=68 dirtied=3
  9 │ Planning Time: 0.961 ms
 10 │ Execution Time: 528.948 ms
```

## Sort with different select order

```sql
explain (analyze, buffers)
select customerid, categoryid, weekday, total
from shopping
order by weekday,total,categoryid,customerid;

    │ QUERY PLAN
────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  1 │ Sort  (cost=140936.84..143436.84 rows=1000000 width=30) (actual time=1227.923..1343.040 rows=1000000 loops=1)
  2 │   Sort Key: weekday, total, categoryid, customerid
  3 │   Sort Method: external merge  Disk: 41160kB
  4 │   Buffers: shared hit=7364, temp read=10283 written=10306
  5 │   ->  Seq Scan on shopping  (cost=0.00..17353.00 rows=1000000 width=30) (actual time=0.017..68.671 rows=1000000 loops=1)
  6 │         Buffers: shared hit=7353
  7 │ Planning:
  8 │   Buffers: shared hit=60
  9 │ Planning Time: 0.241 ms
 10 │ Execution Time: 1374.934 ms
```

## Group by with the same select order 

```sql
explain(analyze, timing off)
select customerid, categoryid, weekday, avg(total::numeric)
from shopping
group by customerid,categoryid,weekday; 

   │ QUERY PLAN
───┼───────────────────────────────────────────────────────────────────────────────────────────────────────
 1 │ HashAggregate  (cost=104540.50..124317.24 rows=488389 width=54) (actual rows=999339 loops=1)
 2 │   Group Key: customerid, categoryid, weekday
 3 │   Planned Partitions: 32  Batches: 165  Memory Usage: 8249kB  Disk Usage: 63056kB
 4 │   ->  Seq Scan on shopping  (cost=0.00..17353.00 rows=1000000 width=30) (actual rows=1000000 loops=1)
 5 │ Planning Time: 0.423 ms
 6 │ JIT:
 7 │   Functions: 11
 8 │   Options: Inlining false, Optimization false, Expressions true, Deforming true
 9 │ Execution Time: 1078.826 ms
```

## Group by with different select order 

```sql
explain(analyze, timing off)
select customerid, categoryid, weekday, avg(total::numeric)
from shopping
group by weekday,categoryid,customerid; 

   │ QUERY PLAN
───┼───────────────────────────────────────────────────────────────────────────────────────────────────────
 1 │ HashAggregate  (cost=104540.50..124317.24 rows=488389 width=54) (actual rows=999339 loops=1)
 2 │   Group Key: weekday, categoryid, customerid
 3 │   Planned Partitions: 32  Batches: 161  Memory Usage: 8249kB  Disk Usage: 63064kB
 4 │   ->  Seq Scan on shopping  (cost=0.00..17353.00 rows=1000000 width=30) (actual rows=1000000 loops=1)
 5 │ Planning Time: 0.836 ms
 6 │ JIT:
 7 │   Functions: 11
 8 │   Options: Inlining false, Optimization false, Expressions true, Deforming true
 9 │ Execution Time: 1087.051 ms
```
