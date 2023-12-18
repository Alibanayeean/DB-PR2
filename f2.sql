CREATE FUNCTION f2 (st timestamp with time zone, en timestamp with time zone)
RETURNS TABLE(
	supervisor character varying(10),
	cost_sum integer
)
AS $$
BEGIN
	RETURN QUERY
	SELECT supervisor, SUM(cost)
		FROM (
			SELECT supervisor, cost
				FROM parking_receipt AS pr
					JOIN citizen ON pr.driver=citizen.ssn
				WHERE st <= enter_time
					AND en >= exit_time
			UNION
			SELECT supervisor, cost
				FROM trip_receipt
					NATURAL JOIN citizen
				WHERE st <= start_time
					AND en >= end_time
			UNION
			SELECT supervisor, cost
				FROM urban_service_receipt AS usr
					JOIN home ON usr.owner=home.hid
					JOIN citizen ON home.owner=citizen.ssn
				WHERE st <= date
					AND en >= date
		)
	GROUP BY supervisor
	ORDER BY SUM(cost) DESC
	LIMIT 5;
END; $$
LANGUAGE plpgsql;