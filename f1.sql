CREATE FUNCTION f1 (ssn integer, st time, en time)
RETURNS integer AS $$
DECLARE
	trip_count integer;
BEGIN
	SELECT COUNT(*)
		INTO trip_count
		FROM trip
			NATURAL JOIN trip_receipt
			NATURAL JOIN citizen
		WHERE driver=ssn
			AND st <= start_time
			AND en >= end_time
		GROUP BY trip_code
		HAVING 
			(
				SUM(CASE WHEN gender = 'female' THEN 1 ELSE 0 END) * 1.0 / 
				(CASE WHEN SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) > 0 THEN SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) ELSE 1 END)
			) >= 0.6;
	RETURN trip_count;
END; $$
LANGUAGE plpgsql;