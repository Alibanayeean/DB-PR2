PGDMP  6                    {         
   smart-city     16.1 (Ubuntu 16.1-1.pgdg22.04+1)     16.1 (Ubuntu 16.1-1.pgdg22.04+1) �               0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    25107 
   smart-city    DATABASE     x   CREATE DATABASE "smart-city" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE "smart-city";
                postgres    false                       1255    25415 "   balance_checking_parking_receipt()    FUNCTION       CREATE FUNCTION public.balance_checking_parking_receipt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (select sum(balance) from citizen_acc where NEW.driver = ssn) <= 0 then
        RAISE EXCEPTION 'Balance less than zero';
    END IF;
    RETURN NEW;
END;
$$;
 9   DROP FUNCTION public.balance_checking_parking_receipt();
       public          postgres    false                       1255    25416    balance_checking_trip_receipt()    FUNCTION       CREATE FUNCTION public.balance_checking_trip_receipt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (select sum(balance) from citizen_acc where citizen_acc.ssn = New.ssn) <= 0 then
        RAISE EXCEPTION 'Balance less than zero';
    END IF;
    RETURN NEW;
END;
$$;
 6   DROP FUNCTION public.balance_checking_trip_receipt();
       public          postgres    false            �            1255    25436    check_enter_exit_time()    FUNCTION     �   CREATE FUNCTION public.check_enter_exit_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.enter_time >= NEW.exit_time THEN
        RAISE EXCEPTION 'Start time must be less than end time';
    END IF;
    RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.check_enter_exit_time();
       public          postgres    false                       1255    25431    check_start_end_time()    FUNCTION     �   CREATE FUNCTION public.check_start_end_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.start_time >= NEW.end_time THEN
        RAISE EXCEPTION 'Start time must be less than end time';
    END IF;
    RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.check_start_end_time();
       public          postgres    false            	           1255    25440 I   f1(character varying, timestamp with time zone, timestamp with time zone)    FUNCTION     �  CREATE FUNCTION public.f1(person character varying, st timestamp with time zone, en timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	trip_count integer;
BEGIN
	SELECT COUNT(*)
		INTO trip_count
	FROM
		(SELECT trip_code
			FROM trip
				NATURAL JOIN trip_receipt
				NATURAL JOIN citizen
			WHERE driver=person
				AND st <= start_time
				AND en >= end_time
			GROUP BY trip_code
			HAVING 
				(
					SUM(CASE WHEN gender = 'female' THEN 1 ELSE 0 END) * 1.0 / 
					(CASE WHEN SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) > 0 THEN SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) ELSE 1 END)
				) >= 0.6);
	RETURN trip_count;
END; $$;
 m   DROP FUNCTION public.f1(person character varying, st timestamp with time zone, en timestamp with time zone);
       public          postgres    false                       1255    25448    f10(character varying)    FUNCTION     �  CREATE FUNCTION public.f10(person_id character varying) RETURNS TABLE(cost_sum bigint, month timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT SUM(cost) as cost_sum, date_trunc('month', date) AS month
		FROM (
			SELECT cost, enter_time AS date
				FROM parking_receipt AS pr
					JOIN citizen ON pr.driver=citizen.ssn
				WHERE ssn = person_id
			UNION
			SELECT cost, start_time AS date
				FROM trip_receipt
					NATURAL JOIN citizen
				WHERE ssn = person_id
			UNION
			SELECT cost, date
				FROM urban_service_receipt AS usr
					JOIN home ON usr.owner=home.hid
					JOIN citizen ON home.owner=citizen.ssn
				WHERE ssn = person_id
		) as costs_for_one_person_in_a_month
		GROUP BY month;
END; $$;
 7   DROP FUNCTION public.f10(person_id character varying);
       public          postgres    false                       1255    25404    f11(integer, integer)    FUNCTION       CREATE FUNCTION public.f11(src integer, cost integer) RETURNS TABLE(stid integer, loc point)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		WITH RECURSIVE traverse AS (
			SELECT st1.sid, 0 AS dist
				FROM station st1
				WHERE st1.sid = src
			UNION
			SELECT st2.sid, traverse.dist + distance AS dist
				FROM station st2
					JOIN adj_station ON stid_firs = st2.sid OR stid_sec = st2.sid
					JOIN traverse ON stid_firs = traverse.sid OR stid_sec = traverse.sid
		)
		SELECT *
			FROM traverse
			WHERE dist <= cost;
	END; $$;
 5   DROP FUNCTION public.f11(src integer, cost integer);
       public          postgres    false                       1255    25450    f12()    FUNCTION     �  CREATE FUNCTION public.f12() RETURNS TABLE(person character varying, avg_cost numeric)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		select ssn, AVG(cost)
	from (select ssn, cost
		  	FROM trip
			NATURAL JOIN trip_receipt
			NATURAL JOIN citizen
	) as citizen_public_costs
	where citizen_public_costs.ssn in (select ssn
		from personal_car join citizen on citizen.ssn = personal_car.owner)
	group by ssn
	;
	END; $$;
    DROP FUNCTION public.f12();
       public          postgres    false                       1255    25406 7   f13(timestamp with time zone, timestamp with time zone)    FUNCTION     ]  CREATE FUNCTION public.f13(st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(person character varying)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		select distinct ppt1.ssn
	from (
		select citizen.ssn, pr.enter_time, pr.exit_time
			FROM parking_receipt AS pr
			JOIN citizen ON pr.driver=citizen.ssn
			WHERE pr.enter_time >= st AND pr.exit_time <= en
	) as ppt1 --person_parking_time 1
	where ppt1.ssn in (
		select ppt2.ssn
		from (
			select citizen.ssn, pr.enter_time, pr.exit_time
				FROM parking_receipt AS pr
				JOIN citizen ON pr.driver=citizen.ssn
				WHERE pr.enter_time >= st AND pr.exit_time <= en
		) as ppt2 --person_parking_time 2
		where ppt1.ssn = ppt2.ssn 
		and ABS(DATE_PART('day', ppt1.enter_time - ppt2.enter_time)) < 2 
		and ABS(DATE_PART('day', ppt1.enter_time - ppt2.enter_time)) >= 1
	);
	END; $$;
 T   DROP FUNCTION public.f13(st timestamp with time zone, en timestamp with time zone);
       public          postgres    false                       1255    25453    f14(integer, integer)    FUNCTION     
  CREATE FUNCTION public.f14(src integer, dst integer) RETURNS TABLE(stations integer[], total_dist integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	WITH RECURSIVE traverse AS (
		SELECT sid AS node, 0 AS cost, ARRAY[sid] AS path
			FROM station
			WHERE sid = src
		UNION ALL
		SELECT
			CASE WHEN adj.stid_firs = tr.node THEN adj.stid_sec ELSE adj.stid_firs END AS node,
			tr.cost + adj.distance AS cost,
			tr.path || (CASE WHEN adj.stid_firs = tr.node THEN adj.stid_sec ELSE adj.stid_firs END) AS path
		FROM traverse tr
			JOIN adj_station adj ON tr.node = adj.stid_firs OR tr.node = adj.stid_sec
		WHERE adj.stid_firs <> ALL (tr.path)
			AND adj.stid_sec <> ALL (tr.path)
	)
	SELECT path, cost
	FROM traverse
	WHERE node = dst
	ORDER BY cost
	LIMIT 1;
END; $$;
 4   DROP FUNCTION public.f14(src integer, dst integer);
       public          postgres    false                       1255    25412 @   f15(integer, timestamp with time zone, timestamp with time zone)    FUNCTION     /  CREATE FUNCTION public.f15(max_dist integer, st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(ssn character varying, total_dist_traversed integer)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		WITH RECURSIVE traverse AS (
			SELECT st1.sid, 0 AS dist
				FROM station st1
				WHERE st1.sid = 1
			UNION
			SELECT st2.sid, traverse.dist + distance AS dist
				FROM station st2
					JOIN adj_station ON stid_firs = st2.sid OR stid_sec = st2.sid
					JOIN traverse ON stid_firs = traverse.sid OR stid_sec = traverse.sid
		)
		SELECT ssn, SUM(ABS(trav2.dist - trav1.dist)) AS total_dist_traversed
			FROM trip_receipt AS tr
				NATURAL JOIN trip
				JOIN network ON trip.pid = network.pid
				JOIN transportation ON transportation.trid = network.trid
				JOIN traverse AS trav1 ON trav1.sid = tr.start_station
				JOIN traverse AS trav2 ON trav2.sid = tr.end_station
			WHERE st <= start_time
				AND en >= end_time
				AND type = 'bus'
				AND total_dist_traversed <= max_dist
			GROUP BY ssn
			ORDER BY total_dist_traversed DESC;
	END; $$;
 f   DROP FUNCTION public.f15(max_dist integer, st timestamp with time zone, en timestamp with time zone);
       public          postgres    false                       1255    25443 6   f2(timestamp with time zone, timestamp with time zone)    FUNCTION       CREATE FUNCTION public.f2(st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(person character varying, total_cost bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT supervisor AS sp, SUM(cost)
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
	GROUP BY sp
	ORDER BY SUM(cost) DESC
	LIMIT 5;
END; $$;
 S   DROP FUNCTION public.f2(st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            �            1255    25393 6   f3(timestamp with time zone, timestamp with time zone)    FUNCTION     �  CREATE FUNCTION public.f3(st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(ssn character varying, total_dist_traversed integer)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		WITH RECURSIVE traverse AS (
			SELECT st1.sid, 0 AS dist
				FROM station st1
				WHERE st1.sid = 1
			UNION
			SELECT st2.sid, traverse.dist + distance AS dist
				FROM station st2
					JOIN adj_station ON stid_firs = st2.sid OR stid_sec = st2.sid
					JOIN traverse ON stid_firs = traverse.sid OR stid_sec = traverse.sid
		)
		SELECT ssn, SUM(ABS(trav2.dist - trav1.dist)) AS total_dist_traversed
			FROM trip_receipt AS tr
				NATURAL JOIN trip
				JOIN traverse AS trav1 ON trav1.sid = tr.start_station
				JOIN traverse AS trav2 ON trav2.sid = tr.end_station
			WHERE st <= start_time
				AND en >= end_time
			GROUP BY ssn
			ORDER BY total_dist_traversed DESC
			LIMIT 5;
	END; $$;
 S   DROP FUNCTION public.f3(st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            �            1255    25394 ?   f4(integer, timestamp with time zone, timestamp with time zone)    FUNCTION     �  CREATE FUNCTION public.f4(stid integer, st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(station_cnt integer, month timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT COUNT(cid), date_trunc('month', start_time) AS month
			FROM public_car AS pc1
				NATURAL JOIN trip
				NATURAL JOIN trip_receipt
			WHERE stid IN (
				SELECT stid
					FROM public_car AS pc2
						NATURAL JOIN trip
						NATURAL JOIN trip_receipt
						NATURAL JOIN path
						JOIN station_path on path.pid = station_path.pid
					WHERE cid = pc1.cid
						AND start_time >= st
						AND end_time <= et
			)
			GROUP BY month;
	END $$;
 a   DROP FUNCTION public.f4(stid integer, st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            �            1255    25395 	   f5(point)    FUNCTION     �   CREATE FUNCTION public.f5(pnt point) RETURNS TABLE(station integer)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT sid
			FROM station
			ORDER BY loc <-> pnt
			LIMIT 5;
	END $$;
 $   DROP FUNCTION public.f5(pnt point);
       public          postgres    false            �            1255    25396 6   f6(timestamp with time zone, timestamp with time zone)    FUNCTION       CREATE FUNCTION public.f6(st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(ssn character varying, station_cnt integer)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT ssn, COUNT(station) AS trip
			FROM (
				SELECT tr.start_station AS station, ssn
					FROM trip_receipt AS tr
					WHERE tr.start_time >= st
				UNION 
				SELECT tr.end_station AS station, ssn FROM trip_receipt AS tr
					WHERE tr.end_time <= et
			) AS stations
			GROUP BY ssn
			ORDER BY COUNT(station)
			LIMIT 5;
	END $$;
 S   DROP FUNCTION public.f6(st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            
           1255    25444 6   f7(timestamp with time zone, timestamp with time zone)    FUNCTION     �  CREATE FUNCTION public.f7(st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(person character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	select my_table.ssn 
		from ((select ssn, sum(end_time - start_time) as metro_time
			from trip_receipt natural join trip
			natural join public_car
			natural join transportation
			where type = 'merto'
			and start_time >= st
			and end_time <= en
			   group by ssn
			   ) as t1
		cross join
		(select sum(end_time - start_time) as bus_time
			from trip_receipt natural join trip
			natural join public_car
			natural join transportation
			where type = 'bus') as t2) as my_table
		where my_table.metro_time > my_table.bus_time;
END; $$;
 S   DROP FUNCTION public.f7(st timestamp with time zone, en timestamp with time zone);
       public          postgres    false                       1255    25446 ?   f8(integer, timestamp with time zone, timestamp with time zone)    FUNCTION     r  CREATE FUNCTION public.f8(parking_id integer, st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(total_cars bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	select count(*) as cars_with_specify_brand_and_color
		from (
			select prid, pid, car, brand, color, enter_time, exit_time
			from parking_receipt as pr
			natural join parking
			join car on car.cid = pr.car

			where enter_time <= st
			  and exit_time >= en
			  and pid = parking_id
		) as cp

		where cp.color not in (
				  select cp_color.color
					from 
					(select * 
					from parking_receipt as pr
					natural join parking
					join car on car.cid = pr.car)
					as cp_color
					where not cp.car = cp_color.cid
					  and enter_time <= st
					  and exit_time >= en
					  and pid = parking_id 
			  ) 
			  and cp.brand not in (
				  select cp_brand.brand
					from 
					(select * 
					from parking_receipt as pr
					natural join parking
					join car on car.cid = pr.car)
					as cp_brand
				  where not cp.car = cp_brand.cid
					  and enter_time <= st
					  and exit_time >= en
					  and pid = parking_id
			  );

END $$;
 g   DROP FUNCTION public.f8(parking_id integer, st timestamp with time zone, en timestamp with time zone);
       public          postgres    false                       1255    25447    f9(integer)    FUNCTION     #  CREATE FUNCTION public.f9(parking_id integer) RETURNS TABLE(total_cars bigint, time_with_max_cars timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	select count(car2) as number_of_cars, st1
from
(select car as car1, enter_time as st1, exit_time as et1
	from parking_receipt as pr
	where pr.pid = 0
) as t1
join 
(select car as car2, enter_time as st2, exit_time as et2
	from parking_receipt as pr
	where pr.pid = 0) as t2
on t1.st1 between t2.st2 and t2.et2

group by car1, st1
order by number_of_cars
limit 1;
END $$;
 -   DROP FUNCTION public.f9(parking_id integer);
       public          postgres    false                       1255    25413    t1_function()    FUNCTION     �  CREATE FUNCTION public.t1_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.cost > (select sum(balacne) from citizen_acc where NEW.driver = citizen_acc.ssn)	Then
		UPDATE citizen_acc as ca1
			SET ca1.balance = NEW.cost - (select sum(citizen_acc.balacne) from citizen_acc where NEW.driver = citizen_acc.ssn)
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn in (
										   select pc.owner as ssn
										   from personal_car as pc
										   where pc.cid = NEW.car
									   )
									   ORDER BY acc_no LIMIT 1);
		UPDATE citizen_acc as ca
    	SET ca.balance = 0
    	WHERE NEW.driver = ca.ssn;
	END IF;
	
  RETURN NEW;
END;
$$;
 $   DROP FUNCTION public.t1_function();
       public          postgres    false            �            1255    25425    t4_pr_function()    FUNCTION     E  CREATE FUNCTION public.t4_pr_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE citizen_acc as ca1
			SET ca1.balance = ca1.balance - NEW.cost
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn= New.driver
									   ORDER BY acc_no LIMIT 1);
  RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.t4_pr_function();
       public          postgres    false                        1255    25426    t4_tr_function()    FUNCTION     B  CREATE FUNCTION public.t4_tr_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE citizen_acc as ca1
			SET ca1.balance = ca1.balance - NEW.cost
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn= New.ssn
									   ORDER BY acc_no LIMIT 1);
  RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.t4_tr_function();
       public          postgres    false                       1255    25427    t4_usr_function()    FUNCTION     p  CREATE FUNCTION public.t4_usr_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE citizen_acc as ca1
			SET ca1.balance = ca1.balance - NEW.cost
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn = (select owner from home where New.owner = home.hid)
									   ORDER BY acc_no LIMIT 1);
  RETURN NEW;
END;
$$;
 (   DROP FUNCTION public.t4_usr_function();
       public          postgres    false            �            1259    25112    adj_station    TABLE     �   CREATE TABLE public.adj_station (
    stid_firs integer NOT NULL,
    stid_sec integer NOT NULL,
    distance integer NOT NULL,
    duration integer NOT NULL
);
    DROP TABLE public.adj_station;
       public         heap    postgres    false            �            1259    25115    car    TABLE     �   CREATE TABLE public.car (
    cid integer NOT NULL,
    color character varying(32) NOT NULL,
    brand character varying(32) NOT NULL
);
    DROP TABLE public.car;
       public         heap    postgres    false            �            1259    25118    citizen    TABLE     �  CREATE TABLE public.citizen (
    ssn character varying(10) NOT NULL,
    dob date NOT NULL,
    fname character varying(256) NOT NULL,
    lname character varying(256) NOT NULL,
    gender character varying(10) NOT NULL,
    supervisor character varying(10) NOT NULL,
    CONSTRAINT gender CHECK (((gender)::text = ANY (ARRAY[('male'::character varying)::text, ('female'::character varying)::text])))
);
    DROP TABLE public.citizen;
       public         heap    postgres    false            �            1259    25124    citizen_acc    TABLE     �   CREATE TABLE public.citizen_acc (
    ssn character varying(10) NOT NULL,
    acc_no character varying(16) NOT NULL,
    balance integer DEFAULT 0 NOT NULL
);
    DROP TABLE public.citizen_acc;
       public         heap    postgres    false            �            1259    25128    history    TABLE     I   CREATE TABLE public.history (
    code character varying(32) NOT NULL
);
    DROP TABLE public.history;
       public         heap    postgres    false            �            1259    25131    home    TABLE     �   CREATE TABLE public.home (
    address character varying(256) NOT NULL,
    hid integer NOT NULL,
    owner character varying(10) NOT NULL,
    loc point NOT NULL
);
    DROP TABLE public.home;
       public         heap    postgres    false            �            1259    25134    network    TABLE     �   CREATE TABLE public.network (
    nid integer NOT NULL,
    cost_per_km integer NOT NULL,
    path integer NOT NULL,
    trid integer NOT NULL
);
    DROP TABLE public.network;
       public         heap    postgres    false            �            1259    25137    parking    TABLE     d  CREATE TABLE public.parking (
    cost integer NOT NULL,
    name character varying(256) NOT NULL,
    pid integer NOT NULL,
    capacity integer NOT NULL,
    start_time time with time zone DEFAULT '08:00:00-05'::time with time zone NOT NULL,
    end_time time with time zone DEFAULT '23:59:00-05'::time with time zone NOT NULL,
    loc point NOT NULL
);
    DROP TABLE public.parking;
       public         heap    postgres    false            �            1259    25144    parking_receipt    TABLE     H  CREATE TABLE public.parking_receipt (
    prid integer NOT NULL,
    pid integer,
    car integer NOT NULL,
    driver character varying(10) NOT NULL,
    history_code character varying(32) NOT NULL,
    cost integer NOT NULL,
    exit_time timestamp with time zone NOT NULL,
    enter_time timestamp with time zone NOT NULL
);
 #   DROP TABLE public.parking_receipt;
       public         heap    postgres    false            �            1259    25147    path    TABLE     a   CREATE TABLE public.path (
    pid integer NOT NULL,
    name character varying(256) NOT NULL
);
    DROP TABLE public.path;
       public         heap    postgres    false            �            1259    25150    personal_car    TABLE     i   CREATE TABLE public.personal_car (
    cid integer NOT NULL,
    owner character varying(10) NOT NULL
);
     DROP TABLE public.personal_car;
       public         heap    postgres    false            �            1259    25153 
   public_car    TABLE     �   CREATE TABLE public.public_car (
    cid integer NOT NULL,
    trid integer NOT NULL,
    driver character varying(10) NOT NULL
);
    DROP TABLE public.public_car;
       public         heap    postgres    false            �            1259    25156    public_car_driver    TABLE     v   CREATE TABLE public.public_car_driver (
    public_car integer NOT NULL,
    driver character varying(10) NOT NULL
);
 %   DROP TABLE public.public_car_driver;
       public         heap    postgres    false            �            1259    25159    station    TABLE     s   CREATE TABLE public.station (
    name character varying(256) NOT NULL,
    sid integer NOT NULL,
    loc point
);
    DROP TABLE public.station;
       public         heap    postgres    false            �            1259    25162    station_path    TABLE     Z   CREATE TABLE public.station_path (
    stid integer NOT NULL,
    pid integer NOT NULL
);
     DROP TABLE public.station_path;
       public         heap    postgres    false            �            1259    25165 	   trans_car    TABLE     h   CREATE TABLE public.trans_car (
    transportation integer NOT NULL,
    public_car integer NOT NULL
);
    DROP TABLE public.trans_car;
       public         heap    postgres    false            �            1259    25168    transportation    TABLE     k   CREATE TABLE public.transportation (
    trid integer NOT NULL,
    type character varying(10) NOT NULL
);
 "   DROP TABLE public.transportation;
       public         heap    postgres    false            �            1259    25171    trip    TABLE     �   CREATE TABLE public.trip (
    trip_code character varying(32) NOT NULL,
    driver character varying(10) NOT NULL,
    car integer NOT NULL,
    path integer NOT NULL
);
    DROP TABLE public.trip;
       public         heap    postgres    false            �            1259    25174    trip_receipt    TABLE     o  CREATE TABLE public.trip_receipt (
    history_code character varying(32) NOT NULL,
    start_station integer NOT NULL,
    end_station integer NOT NULL,
    ssn character varying(10) NOT NULL,
    trip_code character varying(32) NOT NULL,
    cost integer NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL
);
     DROP TABLE public.trip_receipt;
       public         heap    postgres    false            �            1259    25177    urban_service    TABLE     (  CREATE TABLE public.urban_service (
    type character varying(16) NOT NULL,
    usid integer NOT NULL,
    CONSTRAINT urban_service_type_check CHECK (((type)::text = ANY (ARRAY[('water'::character varying)::text, ('electricity'::character varying)::text, ('gas'::character varying)::text])))
);
 !   DROP TABLE public.urban_service;
       public         heap    postgres    false            �            1259    25181    urban_service_receipt    TABLE     "  CREATE TABLE public.urban_service_receipt (
    code character varying(32) NOT NULL,
    date timestamp with time zone NOT NULL,
    usage integer NOT NULL,
    owner integer NOT NULL,
    usid integer NOT NULL,
    history_code character varying(32) NOT NULL,
    cost integer NOT NULL
);
 )   DROP TABLE public.urban_service_receipt;
       public         heap    postgres    false            �            1259    25464    view_2    VIEW       CREATE VIEW public.view_2 AS
 SELECT station,
    count(ssn) AS passengers
   FROM ( SELECT tr.start_station AS station,
            tr.ssn
           FROM public.trip_receipt tr
          WHERE (abs(date_part('day'::text, (tr.start_time - CURRENT_TIMESTAMP))) <= (1)::double precision)
        UNION
         SELECT tr.end_station AS station,
            tr.ssn
           FROM public.trip_receipt tr
          WHERE (abs(date_part('day'::text, (tr.end_time - CURRENT_TIMESTAMP))) <= (1)::double precision)) stations
  GROUP BY station;
    DROP VIEW public.view_2;
       public          postgres    false    233    233    233    233    233            �            1259    25470    view_3    VIEW       CREATE VIEW public.view_3 AS
 SELECT public_car AS metro_number,
    count(ssn) AS number_of_people
   FROM ( SELECT DISTINCT trip_receipt.ssn,
            trans_car.public_car
           FROM (((((public.trip
             JOIN public.trip_receipt USING (trip_code))
             CROSS JOIN public.path)
             JOIN public.network USING (path))
             JOIN public.transportation USING (trid))
             CROSS JOIN public.trans_car)
          WHERE ((transportation.type)::text = 'metro'::text)) my_table
  GROUP BY public_car;
    DROP VIEW public.view_3;
       public          postgres    false    231    233    233    232    232    221    221    224    230    231            �            1259    25485    view_4    VIEW       CREATE VIEW public.view_4 AS
 SELECT hid
   FROM ( SELECT home.hid,
            urban_service_receipt.cost
           FROM ((public.urban_service
             JOIN public.urban_service_receipt USING (usid))
             JOIN public.home ON ((urban_service_receipt.owner = home.hid)))
          WHERE (((urban_service.type)::text = 'electricity'::text) AND (urban_service_receipt.date >= (CURRENT_TIMESTAMP - '1 mon'::interval)) AND (urban_service_receipt.date <= CURRENT_TIMESTAMP))) h
  GROUP BY hid
 HAVING (sum(cost) > 1);
    DROP VIEW public.view_4;
       public          postgres    false    235    235    235    235    234    234    220            �          0    25112    adj_station 
   TABLE DATA           N   COPY public.adj_station (stid_firs, stid_sec, distance, duration) FROM stdin;
    public          postgres    false    215   ��       �          0    25115    car 
   TABLE DATA           0   COPY public.car (cid, color, brand) FROM stdin;
    public          postgres    false    216   ��       �          0    25118    citizen 
   TABLE DATA           M   COPY public.citizen (ssn, dob, fname, lname, gender, supervisor) FROM stdin;
    public          postgres    false    217    �       �          0    25124    citizen_acc 
   TABLE DATA           ;   COPY public.citizen_acc (ssn, acc_no, balance) FROM stdin;
    public          postgres    false    218   c�       �          0    25128    history 
   TABLE DATA           '   COPY public.history (code) FROM stdin;
    public          postgres    false    219   Z�       �          0    25131    home 
   TABLE DATA           8   COPY public.home (address, hid, owner, loc) FROM stdin;
    public          postgres    false    220   ��       �          0    25134    network 
   TABLE DATA           ?   COPY public.network (nid, cost_per_km, path, trid) FROM stdin;
    public          postgres    false    221   O      �          0    25137    parking 
   TABLE DATA           W   COPY public.parking (cost, name, pid, capacity, start_time, end_time, loc) FROM stdin;
    public          postgres    false    222   �      �          0    25144    parking_receipt 
   TABLE DATA           l   COPY public.parking_receipt (prid, pid, car, driver, history_code, cost, exit_time, enter_time) FROM stdin;
    public          postgres    false    223   �      �          0    25147    path 
   TABLE DATA           )   COPY public.path (pid, name) FROM stdin;
    public          postgres    false    224   �&      �          0    25150    personal_car 
   TABLE DATA           2   COPY public.personal_car (cid, owner) FROM stdin;
    public          postgres    false    225   (      �          0    25153 
   public_car 
   TABLE DATA           7   COPY public.public_car (cid, trid, driver) FROM stdin;
    public          postgres    false    226   �*      �          0    25156    public_car_driver 
   TABLE DATA           ?   COPY public.public_car_driver (public_car, driver) FROM stdin;
    public          postgres    false    227   +      �          0    25159    station 
   TABLE DATA           1   COPY public.station (name, sid, loc) FROM stdin;
    public          postgres    false    228   +      �          0    25162    station_path 
   TABLE DATA           1   COPY public.station_path (stid, pid) FROM stdin;
    public          postgres    false    229   �2      �          0    25165 	   trans_car 
   TABLE DATA           ?   COPY public.trans_car (transportation, public_car) FROM stdin;
    public          postgres    false    230   �2      �          0    25168    transportation 
   TABLE DATA           4   COPY public.transportation (trid, type) FROM stdin;
    public          postgres    false    231   �2      �          0    25171    trip 
   TABLE DATA           <   COPY public.trip (trip_code, driver, car, path) FROM stdin;
    public          postgres    false    232   �3      �          0    25174    trip_receipt 
   TABLE DATA           |   COPY public.trip_receipt (history_code, start_station, end_station, ssn, trip_code, cost, start_time, end_time) FROM stdin;
    public          postgres    false    233   2M      �          0    25177    urban_service 
   TABLE DATA           3   COPY public.urban_service (type, usid) FROM stdin;
    public          postgres    false    234   �`      �          0    25181    urban_service_receipt 
   TABLE DATA           c   COPY public.urban_service_receipt (code, date, usage, owner, usid, history_code, cost) FROM stdin;
    public          postgres    false    235   -a                 2606    25190    adj_station adj_station_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.adj_station
    ADD CONSTRAINT adj_station_pkey PRIMARY KEY (stid_firs, stid_sec);
 F   ALTER TABLE ONLY public.adj_station DROP CONSTRAINT adj_station_pkey;
       public            postgres    false    215    215            #           2606    25192     public_car_driver car_owner_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.public_car_driver
    ADD CONSTRAINT car_owner_pkey PRIMARY KEY (public_car, driver);
 J   ALTER TABLE ONLY public.public_car_driver DROP CONSTRAINT car_owner_pkey;
       public            postgres    false    227    227                       2606    25194    car car_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY public.car
    ADD CONSTRAINT car_pkey PRIMARY KEY (cid);
 6   ALTER TABLE ONLY public.car DROP CONSTRAINT car_pkey;
       public            postgres    false    216                       2606    25196    citizen_acc citizen_acc_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.citizen_acc
    ADD CONSTRAINT citizen_acc_pkey PRIMARY KEY (ssn, acc_no);
 F   ALTER TABLE ONLY public.citizen_acc DROP CONSTRAINT citizen_acc_pkey;
       public            postgres    false    218    218                       2606    25198    citizen citizen_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.citizen
    ADD CONSTRAINT citizen_pkey PRIMARY KEY (ssn);
 >   ALTER TABLE ONLY public.citizen DROP CONSTRAINT citizen_pkey;
       public            postgres    false    217                       2606    25200    history history_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_pkey PRIMARY KEY (code);
 >   ALTER TABLE ONLY public.history DROP CONSTRAINT history_pkey;
       public            postgres    false    219                       2606    25202    home home_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY public.home
    ADD CONSTRAINT home_pkey PRIMARY KEY (hid);
 8   ALTER TABLE ONLY public.home DROP CONSTRAINT home_pkey;
       public            postgres    false    220                       2606    25204    network network_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_pkey PRIMARY KEY (nid);
 >   ALTER TABLE ONLY public.network DROP CONSTRAINT network_pkey;
       public            postgres    false    221                       2606    25206    parking parking_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.parking
    ADD CONSTRAINT parking_pkey PRIMARY KEY (pid);
 >   ALTER TABLE ONLY public.parking DROP CONSTRAINT parking_pkey;
       public            postgres    false    222                       2606    25208 $   parking_receipt parking_receipt_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_pkey PRIMARY KEY (history_code);
 N   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_pkey;
       public            postgres    false    223                       2606    25210    path path_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY public.path
    ADD CONSTRAINT path_pkey PRIMARY KEY (pid);
 8   ALTER TABLE ONLY public.path DROP CONSTRAINT path_pkey;
       public            postgres    false    224                       2606    25212    personal_car personal_car_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.personal_car
    ADD CONSTRAINT personal_car_pkey PRIMARY KEY (cid);
 H   ALTER TABLE ONLY public.personal_car DROP CONSTRAINT personal_car_pkey;
       public            postgres    false    225            !           2606    25214    public_car public_car_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_pkey PRIMARY KEY (cid);
 D   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_pkey;
       public            postgres    false    226            '           2606    25216    station_path station_path_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.station_path
    ADD CONSTRAINT station_path_pkey PRIMARY KEY (stid, pid);
 H   ALTER TABLE ONLY public.station_path DROP CONSTRAINT station_path_pkey;
       public            postgres    false    229    229            %           2606    25218    station station_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.station
    ADD CONSTRAINT station_pkey PRIMARY KEY (sid);
 >   ALTER TABLE ONLY public.station DROP CONSTRAINT station_pkey;
       public            postgres    false    228            )           2606    25220    trans_car trans_car_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.trans_car
    ADD CONSTRAINT trans_car_pkey PRIMARY KEY (transportation, public_car);
 B   ALTER TABLE ONLY public.trans_car DROP CONSTRAINT trans_car_pkey;
       public            postgres    false    230    230            +           2606    25222 "   transportation transportation_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.transportation
    ADD CONSTRAINT transportation_pkey PRIMARY KEY (trid);
 L   ALTER TABLE ONLY public.transportation DROP CONSTRAINT transportation_pkey;
       public            postgres    false    231                       2606    25223 (   transportation transportation_type_check    CHECK CONSTRAINT     �   ALTER TABLE public.transportation
    ADD CONSTRAINT transportation_type_check CHECK (((type)::text = ANY (ARRAY[('taxi'::character varying)::text, ('bus'::character varying)::text, ('metro'::character varying)::text]))) NOT VALID;
 M   ALTER TABLE public.transportation DROP CONSTRAINT transportation_type_check;
       public          postgres    false    231    231            -           2606    25225    trip trip_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_pkey PRIMARY KEY (trip_code);
 8   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_pkey;
       public            postgres    false    232            /           2606    25227    trip_receipt trip_receipt_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_pkey PRIMARY KEY (history_code);
 H   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_pkey;
       public            postgres    false    233            1           2606    25229     urban_service urban_service_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.urban_service
    ADD CONSTRAINT urban_service_pkey PRIMARY KEY (usid);
 J   ALTER TABLE ONLY public.urban_service DROP CONSTRAINT urban_service_pkey;
       public            postgres    false    234            3           2606    25231 0   urban_service_receipt urban_service_receipt_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.urban_service_receipt
    ADD CONSTRAINT urban_service_receipt_pkey PRIMARY KEY (history_code);
 Z   ALTER TABLE ONLY public.urban_service_receipt DROP CONSTRAINT urban_service_receipt_pkey;
       public            postgres    false    235            U           2620    25417    trip_receipt t2_tr    TRIGGER     �   CREATE TRIGGER t2_tr BEFORE INSERT ON public.trip_receipt FOR EACH ROW EXECUTE FUNCTION public.balance_checking_trip_receipt();
 +   DROP TRIGGER t2_tr ON public.trip_receipt;
       public          postgres    false    233    264            V           2620    25432    trip_receipt t5    TRIGGER     t   CREATE TRIGGER t5 BEFORE INSERT ON public.trip_receipt FOR EACH ROW EXECUTE FUNCTION public.check_start_end_time();
 (   DROP TRIGGER t5 ON public.trip_receipt;
       public          postgres    false    258    233            T           2620    25438    parking_receipt t5_pr    TRIGGER     {   CREATE TRIGGER t5_pr BEFORE INSERT ON public.parking_receipt FOR EACH ROW EXECUTE FUNCTION public.check_enter_exit_time();
 .   DROP TRIGGER t5_pr ON public.parking_receipt;
       public          postgres    false    223    239            W           2620    25437    trip_receipt t5_tr    TRIGGER     w   CREATE TRIGGER t5_tr BEFORE INSERT ON public.trip_receipt FOR EACH ROW EXECUTE FUNCTION public.check_start_end_time();
 +   DROP TRIGGER t5_tr ON public.trip_receipt;
       public          postgres    false    233    258            4           2606    25232 &   adj_station adj_station_stid_firs_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.adj_station
    ADD CONSTRAINT adj_station_stid_firs_fkey FOREIGN KEY (stid_firs) REFERENCES public.station(sid);
 P   ALTER TABLE ONLY public.adj_station DROP CONSTRAINT adj_station_stid_firs_fkey;
       public          postgres    false    215    3365    228            5           2606    25237 %   adj_station adj_station_stid_sec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.adj_station
    ADD CONSTRAINT adj_station_stid_sec_fkey FOREIGN KEY (stid_sec) REFERENCES public.station(sid);
 O   ALTER TABLE ONLY public.adj_station DROP CONSTRAINT adj_station_stid_sec_fkey;
       public          postgres    false    3365    228    215            D           2606    25242 &   public_car_driver car_owner_owner_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car_driver
    ADD CONSTRAINT car_owner_owner_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn);
 P   ALTER TABLE ONLY public.public_car_driver DROP CONSTRAINT car_owner_owner_fkey;
       public          postgres    false    227    3343    217            7           2606    25247     citizen_acc citizen_acc_ssn_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.citizen_acc
    ADD CONSTRAINT citizen_acc_ssn_fkey FOREIGN KEY (ssn) REFERENCES public.citizen(ssn);
 J   ALTER TABLE ONLY public.citizen_acc DROP CONSTRAINT citizen_acc_ssn_fkey;
       public          postgres    false    218    3343    217            6           2606    25252    citizen citizen_supervisor_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.citizen
    ADD CONSTRAINT citizen_supervisor_fkey FOREIGN KEY (supervisor) REFERENCES public.citizen(ssn) NOT VALID;
 I   ALTER TABLE ONLY public.citizen DROP CONSTRAINT citizen_supervisor_fkey;
       public          postgres    false    3343    217    217            8           2606    25257    home homes_owner_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.home
    ADD CONSTRAINT homes_owner_fkey FOREIGN KEY (owner) REFERENCES public.citizen(ssn) NOT VALID;
 ?   ALTER TABLE ONLY public.home DROP CONSTRAINT homes_owner_fkey;
       public          postgres    false    3343    217    220            9           2606    25262    network network_trid_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_trid_fkey FOREIGN KEY (trid) REFERENCES public.path(pid) NOT VALID;
 C   ALTER TABLE ONLY public.network DROP CONSTRAINT network_trid_fkey;
       public          postgres    false    224    3357    221            :           2606    25267    network network_trid_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_trid_fkey1 FOREIGN KEY (trid) REFERENCES public.transportation(trid) NOT VALID;
 D   ALTER TABLE ONLY public.network DROP CONSTRAINT network_trid_fkey1;
       public          postgres    false    231    3371    221            ;           2606    25272 (   parking_receipt parking_receipt_car_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_car_fkey FOREIGN KEY (car) REFERENCES public.car(cid) NOT VALID;
 R   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_car_fkey;
       public          postgres    false    216    223    3341            <           2606    25277 +   parking_receipt parking_receipt_driver_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_driver_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn) NOT VALID;
 U   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_driver_fkey;
       public          postgres    false    223    3343    217            =           2606    25282 1   parking_receipt parking_receipt_history_code_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_history_code_fkey FOREIGN KEY (history_code) REFERENCES public.history(code) NOT VALID;
 [   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_history_code_fkey;
       public          postgres    false    3347    219    223            >           2606    25287 (   parking_receipt parking_receipt_pid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_pid_fkey FOREIGN KEY (pid) REFERENCES public.parking(pid);
 R   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_pid_fkey;
       public          postgres    false    3353    222    223            ?           2606    25292 "   personal_car personal_car_cid_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.personal_car
    ADD CONSTRAINT personal_car_cid_fkey FOREIGN KEY (cid) REFERENCES public.car(cid);
 L   ALTER TABLE ONLY public.personal_car DROP CONSTRAINT personal_car_cid_fkey;
       public          postgres    false    225    3341    216            @           2606    25297 $   personal_car personal_car_owner_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personal_car
    ADD CONSTRAINT personal_car_owner_fkey FOREIGN KEY (owner) REFERENCES public.citizen(ssn) NOT VALID;
 N   ALTER TABLE ONLY public.personal_car DROP CONSTRAINT personal_car_owner_fkey;
       public          postgres    false    225    217    3343            A           2606    25302    public_car public_car_cid_fkey    FK CONSTRAINT     x   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_cid_fkey FOREIGN KEY (cid) REFERENCES public.car(cid);
 H   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_cid_fkey;
       public          postgres    false    226    3341    216            B           2606    25307 !   public_car public_car_driver_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_driver_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn);
 K   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_driver_fkey;
       public          postgres    false    217    226    3343            E           2606    25312 3   public_car_driver public_car_driver_public_car_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car_driver
    ADD CONSTRAINT public_car_driver_public_car_fkey FOREIGN KEY (public_car) REFERENCES public.public_car(cid) NOT VALID;
 ]   ALTER TABLE ONLY public.public_car_driver DROP CONSTRAINT public_car_driver_public_car_fkey;
       public          postgres    false    226    3361    227            C           2606    25317    public_car public_car_trid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_trid_fkey FOREIGN KEY (trid) REFERENCES public.transportation(trid);
 I   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_trid_fkey;
       public          postgres    false    3371    231    226            F           2606    25322 "   station_path station_path_pid_fkey    FK CONSTRAINT     }   ALTER TABLE ONLY public.station_path
    ADD CONSTRAINT station_path_pid_fkey FOREIGN KEY (pid) REFERENCES public.path(pid);
 L   ALTER TABLE ONLY public.station_path DROP CONSTRAINT station_path_pid_fkey;
       public          postgres    false    3357    224    229            G           2606    25327 #   station_path station_path_stid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.station_path
    ADD CONSTRAINT station_path_stid_fkey FOREIGN KEY (stid) REFERENCES public.station(sid);
 M   ALTER TABLE ONLY public.station_path DROP CONSTRAINT station_path_stid_fkey;
       public          postgres    false    228    229    3365            H           2606    25332 #   trans_car trans_car_public_car_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trans_car
    ADD CONSTRAINT trans_car_public_car_fkey FOREIGN KEY (public_car) REFERENCES public.public_car(cid);
 M   ALTER TABLE ONLY public.trans_car DROP CONSTRAINT trans_car_public_car_fkey;
       public          postgres    false    230    3361    226            I           2606    25337 '   trans_car trans_car_transportation_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trans_car
    ADD CONSTRAINT trans_car_transportation_fkey FOREIGN KEY (transportation) REFERENCES public.transportation(trid);
 Q   ALTER TABLE ONLY public.trans_car DROP CONSTRAINT trans_car_transportation_fkey;
       public          postgres    false    230    3371    231            J           2606    25342    trip trip_car_fkey    FK CONSTRAINT     l   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_car_fkey FOREIGN KEY (car) REFERENCES public.car(cid);
 <   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_car_fkey;
       public          postgres    false    3341    216    232            K           2606    25347    trip trip_driver_fkey    FK CONSTRAINT     v   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_driver_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn);
 ?   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_driver_fkey;
       public          postgres    false    232    3343    217            L           2606    25352    trip trip_path_fkey    FK CONSTRAINT     o   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_path_fkey FOREIGN KEY (path) REFERENCES public.path(pid);
 =   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_path_fkey;
       public          postgres    false    232    224    3357            M           2606    25357 *   trip_receipt trip_receipt_end_station_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_end_station_fkey FOREIGN KEY (end_station) REFERENCES public.station(sid) NOT VALID;
 T   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_end_station_fkey;
       public          postgres    false    233    228    3365            N           2606    25362 +   trip_receipt trip_receipt_history_code_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_history_code_fkey FOREIGN KEY (history_code) REFERENCES public.history(code) NOT VALID;
 U   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_history_code_fkey;
       public          postgres    false    233    219    3347            O           2606    25367 "   trip_receipt trip_receipt_ssn_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_ssn_fkey FOREIGN KEY (ssn) REFERENCES public.citizen(ssn) NOT VALID;
 L   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_ssn_fkey;
       public          postgres    false    217    3343    233            P           2606    25372 ,   trip_receipt trip_receipt_start_station_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_start_station_fkey FOREIGN KEY (start_station) REFERENCES public.station(sid) NOT VALID;
 V   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_start_station_fkey;
       public          postgres    false    233    228    3365            Q           2606    25377 (   trip_receipt trip_receipt_trip_code_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_trip_code_fkey FOREIGN KEY (trip_code) REFERENCES public.trip(trip_code) NOT VALID;
 R   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_trip_code_fkey;
       public          postgres    false    3373    232    233            R           2606    25382 6   urban_service_receipt urban_service_receipt_owner_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urban_service_receipt
    ADD CONSTRAINT urban_service_receipt_owner_fkey FOREIGN KEY (owner) REFERENCES public.home(hid);
 `   ALTER TABLE ONLY public.urban_service_receipt DROP CONSTRAINT urban_service_receipt_owner_fkey;
       public          postgres    false    220    3349    235            S           2606    25387 5   urban_service_receipt urban_service_receipt_usid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urban_service_receipt
    ADD CONSTRAINT urban_service_receipt_usid_fkey FOREIGN KEY (usid) REFERENCES public.urban_service(usid) NOT VALID;
 _   ALTER TABLE ONLY public.urban_service_receipt DROP CONSTRAINT urban_service_receipt_usid_fkey;
       public          postgres    false    234    235    3377            �     x�=�۵�0C�I1���_����-HΟc��do�y-�=��q����8m,]�k�akꣻ��֧�����q2hO�p��G����s��0��ϲ�
���a�*O����42�V�7;ג��V�2�Ғi]A���a��!��B�▸x@d�D��v#�R��.�e}P ���eӴȓK`�S�4�p]c��Th�PyF�1�VE�ڨ:b��:q���y�(���������xV����#�{m����
s����+�"^6�M�WL����HF�,����k�B&(4ᨛ��A<Yi�=E���g;ۣ��Ҭ�[�������9䲱=ԹKfy��n%�{S@&(Z���(1��qI@iwԖ�;Ev��f�#y������Њ���4y�*oV�50�z&���x��A�q�Js�j���S�a����edly��k�sWTOy��#)�����MT���\*jW�d+S6M8�Q[���\m�6,���Ͷ�Q�y���JG}�hfA���ZH,�om`�F����y��̼��      �   \  x�mW�n1<�S�CR��ȵ�^��M��`�(��u�]��x�]Q�pHq�t�����/�����?����+��^N�_/OϿ��rx|9}�yx{���v:���r>��_�u��yk����c���Rټn�},�s	��7���I��A�uu�6��[�<��<P��h�l'�N��x�	qK�B��҇~ۺ�n��$s�#���#���Շ���o��`���t!s���#��z[O���"����Y��,#�l٢3p��
����.��khZ�E3��O�:<ǵ�!ᖱXŜQ㕼�T۝��]�0Ƿ��٠�=g�(�g4u붚Z�Uغ'�cړ2���;��K�'͢�f�-�����Gy����e������[���\����~�����D*��Q���+�T����_��*-�	�@e$�D��!B�2�W��ᒮ�C3�);Ωn�H�CT7P$���&2���4��SOSA�_�tՒ�+畓kFST��Tr�u��wD���{�#)&`�pJ�$��-��	�{j�!I-˽�STҵ���G}�T���p���c����z4?XŦ��1�UL����Y�X�3�+�u��[	{��]�������AS_b-VikqG_r뤋����w
�o��W�]�=���F�
6��[�G(��x��lp\O��p���6b=�z$M%Σ����% G��EM�T�f�;�+J�Z��'���h-a����A5�h&A������}��?3 ���c�2(G讘�5-z��gp2ـ�� N�0#	hX[\[ܢ�ڼ��LI�@��2���S��I\I24B����r���˧����S      �      x�U[I�D+l\W��;HLw��{e�keJB�h�Y�B�~�h��[�|�k�������k�>?��o��_����o��?����i�?�����s�S��Ѣ}?�?~�=I�0�/z=������[ha�?���������}���Ꮯ�c�O��9?����g�hgYG6+[χ���������ٿ,11kh��30d%V߰�-\�5�h��x ����4�؆���~@�N|��kj��h�&�f�Z(�
�X����7JLD�X�7Y��Q��Lѻ�J������nV�D���:JTο.`���5�+0\�,�E�rg�1��æ�r�\~vrƻ�>'JT�v2�qF6�B	����%�_;烕�P�9���3d���>�O���T��;:5$�=�O����1�Dr��ta�v�%����|3$#7Q�1ª��Y%Ώ�NY�B��v���,7J�boK;(�kcz�mR�h�ͅ+��!m�N%S|8���K��h�L���� I�!ՒD����_�h]N�+j�J��ϐ��4��QW_�J��7���S�?(3�c���q����:u_C�B1�qufj��T�Բ_Ț�!OKE�.��gh�S	�,��34�S9C#z�D�1!7�q!��B����X�F	�p��ૡq����6'8gh~�W��Z�����|��s��2�34�#SB�+�
ʝ���p����c:���)�V9Pb��Y�3�y�����*X��ve�כ��߉��G
�����B�B�~���T�;=O��՞���jh�TKBI�4�$�شA-d�+J�bQhZl�����==p1���U`�V�f].��/X�GCk�Z'��95�N����D��6K,{����V�{��v�����s���`U�����0�����j�%�g\P�?C�Q4�\��13e�T�;�sgˍR�O\��MJZ9_�:��������%���4���%�s�oJ��3t��tțƙZ�r��8�>�8-�򒗌�syc�&o���zW�c�a����e�#2��A){��B_R�	����G=<9Y��Tö�U�ۛ�����Դ�!U��E����x�	f���"�F�.�a�Q[PY��7�R�۷Â���&�-�Q=�г-(������ l�j���A��[��X�����$X�4Sa0�+a�i\�<���L�ȯ���@4��']�4�i�/�(]��4����->�&�̸	M�����ӊ^.o�+`�ѭ��d`oWhICù�ߝ��j�v�~#�R#�_)nv��G����A*��ڊ3�}�rTnf�H�)����e�ڞ;2�R	�|1�,myM����J�Ѽ^;�NB�ok��/�a������=!}��X����͸Y\H���MVi[5�oYo�iZ���Ǹlr���!���+��j`�����E߮x ����`f�Ɲ���6�JaTI-�h����4���_�0q�0Z�a�v���jz����MW?�T²�QO���' A)���O��0mr��ha̻�|���v��J �5%s��j8�B�yA��Zm���`�Azn����=I�9嬅�J9;�z��O�dy�C*��N?��Hɒ�"�J�{�h���0��%�3�A��z��;�h�빃+�7����5%�O���r׫�g�Ph��C�����C5�� �W�h��v8�k�7��,3ޔ���=� ��*��c�t�{К������v]*��9`�6wZ���uN�Fm�zLM}j�����S>-RJ�[�7r���\�cW�`柳o=���&��G9�П=M�2�M����Gp�Fǎ��c��e��
Y���j��������3Κk|�=��WX�.���ض�]<�n�m��� ��iMG`��&9�>R�#p=n���F_ �e��-CR�����d9��s�	���'�Vm�zc]�u%�Y���TG�����aHw���C�B�M����>Ǵ�?X=nQ@P����h��p���.�#�k;����r����]Y�r���觤���A�3Õ�ˎ�}*8���1�u~+���֋T�N:�:@P��N)��N�<��[�����Ь����������
�������;��1�~44$`Ϡ:&��j`l�����69'#n��|�CP�5 �Y�����`/����X�!=�/����T2�^��}C�=�c"���p�L�HD�<�^H�1��1�:���&����ƃ���>����v�1>>�E*y��w�1��c�������ʛ;
y�	�tt��=�/4R
�����"�~�F?a����O@[+(�J�����$L?��[�������	i
fd��JN}Y�t�{�qYN�u��4 AO��n���T�tC�t� A��,��[v}u�F"�o@Нޓ����,��,�N�%��Е�=���)��p26��Y�}�Pp�]�;�;�t��"�v|�lMwA$���x�bo�ff��1��jX��}��1�n�1��[;���S�!�"��+�o��!�-9�c��x�j�7��������8 oh��ϯj���HٷG�w��}>&\������`��t#�ϗg��&ӧ��֠�Q+�<H%��1��Q���4:cD����k�q'@������Q�Y���E�M��d��,��Srfe��M��<�{��C\������'�������W�@�}ݨw_�����$=��:�y����0>��~�.[�8�=�R6��jy���'��w�H���=*�G.ί���s�%��޽��3t��3@Эe[n� ��q�A�� ����v������ުL̑�wx�=�7q��TrA/��I`��~^�;����n���~�_^��<u^�%̝6�q���O���7��m�����'��q���# �N,ssne�E*��Q�ʂq��U�=�*������O�B��}U�~7Dv~�'�Ԕ|�4�Y�=�L�|���	(�5��k����VR0M�$�}8~tg6�\@�$�Zިv��M�]��!j���Z�	[����j�-e�[(��}��B�CnKj��}3�������,�_������-��C*�N����q�tB>�]#-_&5�}����8�T����Z3���P�_0y�[���[@)�G!R56�A�7�$�>'�D@���Y�"���vKzF���^Q�.�s�ҭ�eУ�$]�!�Ngܧ1�T\홇a�P�����|;��!U�?��\ E?K�/Į��x�#�j�4,W@�܂�C����!���ɭz@�k����q��jO%����*������}Wd sߤ��@�(��E�nC���ޠhU�X��7m�ۖ�#P(�D�D��#%�R���>��ӦJ*����Gj)��7+#�3��z�j��5h�# �L0������Mz�v����;宎�.{���H�5��R���_X��Qw�H���eP2�����5%���?������]_�ՀR���sY�T<�d-7)w���wwӠ��A	$���Gz�i�|y
��U��_�����δ@�E����c�$���t��(������ߜ��=�'͠�+!��;��(�x�$���\e�7��ߣZK�R.��w��J�AYOJKn���}u��^q�,��L3�� �(TR1w�p*��o�.k=Ѱo��t�<pB���1ƬMJ��0����:�����5���~Y�TC�ln%�띉�y"�(��H�"W�[H5szk��cP�M�=�v"�(�x�#�yOR*��*؂y-Rrԟ�|8�7)7s�s=��)�|uY��G*Q<	Q<�T*�ԥ���)�F?�,�r�9&�y��^��4�ʹA$9��r���з�I�Yo�y!�1~6)w���x���i��B�L��O��Xc��=O��K);^�I!��%Ϙg��,���3k�t��sF��W��I�������LB�竀��w�;¡��ޤҩJGa�U��B���ų��z��enP[���q�_�d��z\�����G3���''��4`j{^�(}�.�� ��_0�g$B@��/� .  �wޤ��:]���)dpP�=�ʼB�ZK��o�O�ۣ÷ʽ�r�/����^l ނ�����'�����F��B�h'��z�}��On��%��-쌜jN��UX?����A=��� �^'��v@}��+�Ō� j=AR�G�Ѻ���{naF�~Ackxj�
JW��1@��D���ꭞ�g�?f��UV-}�m��oRu~��ƇT|��� 5�}�P?��NP:
18ZwRM]%��4,U�ѫt"!�%ݱ3�{�_�x��K��]@���R�������� '�����t������x:XK���>7�/u<o����I�P�YP�,H�Au3�Y8�&ԡU;"\�?���<�')�=2�%>�E*5AWA�16����s$iy��(GWa���_n��8/�.@��dӛX�x:�n����o�)���̘���AP.�>���Ĳ�S-{fԍ�"��Y}����)>w$]�"��T�������>���\�z�ʇH[R���DA�}������`eI�wL� j�_��:�t{��$���G7��9�u�&�N�{	�+@]O�W�%�u�ߤ[����և�}�'�fm�GJ�����kP�C@-��L{��Ju��	��	����`��
@�Ŵ�)xhP�C0a�:��'�6l�	��Ny��	��_m�M�۱�#�#hP���(����B7����tƕ5��۹�A��zS���bPO鵓?��Z%պO��rx� �����4��$�$�S�#%�,R�	���	�z�>�d��*���1��?^��~��������~=�o      �   �  x�5�Y�%!�}�铐�{����#0��3A����-�_�Ӳ�����2���c����{{��&��m���wN�m#��v�_,tAL��ͪ�H�a-^H%�v��`�l�dvB7���N��>L���cgs^���0 �/�`��B�� ��?b9W�	��a?_e��|a*�D�(�	�����ZN�&d�6�Mf:d���e����緙��uo�$�'X������zB��b�92�("��c7:�!'Uz8$O� �tl'����o@�ū!9$�/����u������F����݆��fZ"ki�{'��%2C���̾Ѝ���0+#4P����T�ԯ����:�x�Y��j@��J�CRÒ���XZ��ŗ���_U�m�qYʍ�^�:��ah���j;��GwcW���څ�E�	��Ǡ�1�̖�+��-����ґ�!-�n�%J뼐�Ґb���"��
"m�(!z�/
�(�c궍,�?�j�f�a���+���Xu<d�r˔��b�B��Ø�{��Wz ��+8�_BJ!
~D�(g��bCV��)����z�!�(�]�ֹ�k/EA��ND�xd1��qI��K���#����.j��rɷ�*�Yݢ�e=�I���^a�u��
<�B�BjU��r ��
�B�qr�v�Z�|[-^E���(햵��H@�����Ŷ���孔���Q��LJ8a�{�.���E.��Á���(��at
�)�~x����9��̎b�*2eA+���^M^� �V��D���Y0+��*k@ت�Wv�]�h*i L�,�bV]A�&� �(�J���������ZL�-"B�Q��+=�J�_�W��[*� v����Vn;B��u;��Ů����ߺe�EA���ŚTd�F�YEWa�`b��c�v��V9~̺x�1<A�D !�j��<U-V����`��"�Y_�K��j�4�~ݷE=.�OF!�{�y���ʋ~�W����)�^��2'�g�n�J�����羰 Y$`�g���j��M���P����+�g�i�˘���K���ʰe=���GV��%W�l�,�cG=��K4���c%����R�������S@�Z��P���m���|���U�ea�q��>p�����3������{�㲠����+����V��x��z��g	�e����o}���f��)�镆�5�ܒ�T�Ye��v\l���������~� ۄړ      �   3  x��ɕ%!�;��+$���oǄ�=_/Hs�ȱ�g�Q���9ǌ1s�5��yǬ1߈o�#r��G�wD�x#��s��#��=�#k��k�c��k�=��Uc������1v���c����5��g���8k��S�q�q�1n������w�5�����bT�Z���3�[��x�xs�/�[����xw<et����)��ȧ�O'�R>�|j��~��uq�\W��uy�^ק���ݯ������"�&�*�.g6��:�>�B�F�J�N�R�V�Z�j19�N�N�N�N�N�N�NO�ݴrJ�Z�j�z���������ʞ�π���§ƧʧΧҧ֧ڧ����"������������	`�f����01L�$1QLƤ1_�> ��<�G��#x��}P�x��<�G�����D����Cݧ��u��>�<�G���/�#x��<�G��#V#r<�G��#x��<b��$�#x��<�G��#Nur<�G��#x��<���)�#x��<�G��#��c9�#x��<�G�����/�'�#y$��<�G�H�#g_r<�G�H�#y$��<2���<�G�H�#��髦��e#��M�7}���W��<�G����x$��<�G�H�#y���K�G�H�#y$��<�G����x$��<�G�H�#y��Q�G�H�#y$��<�GVߜr<�G�H�#y$��<���w�K���x,���x,�ǚ}��X<��c�X<��c�Xѷ���c�X<��c�X<��}���X<��c�X��#Я@?�w@�_�~
�-�ǀ��x,����`��X<��c�X<��c�X�_9���x,���x,��$�c�X<��c�X<��cU�Ur<��c�X<��c�X<��G�_5���c��<6��c��<6�=����yl���yl��汣�I9���yl���yl;�A��yl���yl���W��r<6��c���:����s?��B��h�~����g���yl���O��r<6��c��<6��c��<��G_���yl���yl�Ǯ��xl���yl���y��cD�	���qx���qxg��!���8<����8<���DO&r<����8<����8<N�#���8<����8<��㬞u�x���qx���qx��C�����8=7��ԓS�N=;������z~����qx���qx��c�����8<����8<�S=���8<����8<����8���܌n<.����<.����<��O���qy\���qy\�Ǎ��x\���qy\���qy��Q���qy\���qy\��]=]��<.����<.�����P9���qy\���qy\���*���=��H�3m�=��X�s�o���і��qy\���qy\�z��qy\���qy\���q_��=+�y��Q<�G�(ţx��Z�G�(ţx��Q<�GEO�r<�G�(ţx��Q<*{L��Q<�G�(ţx��Q��y9ţx��Q<�G�(�{��Q<�G�(ţx��Q�79ţx��Q<�G�(u{���Q�k����F��o���G���C�G�(ţx��Q<�G�^Nz;���x<����x<����x��9����x<����x</zߑ��x<����x<����#9����x<����x<o�%���x<����x<����^��x<����x<����x��;�����x<����x<�w{y���x<����x<����<��{�=���{�]������o�ƿ�1��{      �      x�m�ˮ-�DǼ_rF�d���N<0�A$����*�;HN�*O,��fuKZ"����o���?�����?�X��_�~;�ʿ������1�<��hz��}?�����G��s����q}�q��kz������⊕9=z<�{�q��6^:��;<�D���<����o��97���{�uĴ���L���3Q�vq&�+�i�'N�&����#%�M�yں��M�u�4�?�n�������"�i�&�wdqB�&�s���;�����z�v�+UD�L��{�n�!�e�<o�G/�\��ww}p�\&�c�����E�˄9;��5J�2a�3h�Q.����V�r�(��&B_E��ynu�5/r�6A�y�ߨ�J�61�y��q�M��ĸ�|0��韛q�ϧ0�˛�!f��1��O�6!����	q���&7}�q��5>�xDt�q����A�ۄ�f������41.�	�I�O�>��r�|� �Dx�;C�I�O��h��y�O�|�(��N+����3�p��u���'���z���'�o��I�O�����u��4A��/�s��e�<^O�s��"ȗ	�yĴ.�C�/�iO�:�����yF� _&�g�ɫ<Q���e�|v�Lx��\D�r��x�6Ob|��WL��_"ȗ	�e��E�/�y�i��n�|� �`Z?�E��6A������:7A�M��ӊ��&ȷ	�5cŌ'}�m�<3���7��M�o��.f>�C�o��i�p�|�u�,,.&ȯ�(�&�3�M��t�ۄ��y�<����Ǆy��iD�!ʏ��}Ĵ5���C��{Ŵ|�SD�1Q���|�_Q~L��i�O�!ʏ������:D�1Q�ϸ?Q~��c�|_1��g'̏[��,���!̏	�,3oq��/a~M��7�1����5a~����/a~M�����(�&�OƴfE���D���V��/Q~M��L+&��(�&ʳ���/Q~M�g�}X�ч(�&�����щ��ʳR��y�Zaֿ���wy�̻���^&���n��G������/+f��&�3CN��%9L��ɦ�՟��z����4�CTr���0�2�D&�	����:��a��1���&��/�"����8e@��&���/�*��񹳥�/�+��~$�� �Hp���pmt<8��WV8*��޳���Y��z�����8ҩ~2�q�x����	G�cb��&	�cƱ1�Y�M?�a�t\�o��qyz?����$9�8E.�����"�ߕ%��W�!;,N������0%P	,Q�X	W�DKd�,Z��6��rY��.s�	!�r�� L@�!u	3���13P雬�Ob�>�A��n.ǛK�Y{R]B��s�ii{F~8�3C:���s9�\�'��C���.�s��l�.G�3�~��.��cf���,]�G��@Z�,!�rL:fT-a�r\
堺�_��+���R�>�K��� u�t�
Q�c��2����q�x�A�%T]�U��@�ڃ��X��@�^��.G���%�&p]�\ΐ6̖�u9z/c	a�we�#��2��"1�r;V�R���vߋ�/��*7̎��R�d��Y.�*��2�A�8���)/زÃ��aŶ���HUx�ߎ�����d�c\�ib�.��K���Z��H�iiv�.��b�bݾ���kw!Om������a���w�d�C��1P>
��p�� ��/��cdHl#,a�r<F��'^��Y̢K�����@{6/�Ĭ���GT�/�xԻ��ph$�Ԣ�޻�vc��/�P�d�c��2$}���8y���p��˱�x��z//����,f^���@�\����y�������3�Tz���y�I��z9�/���D��a4H��m���L�ݪg���g>����2$�1D��!�X�������2�b-"�^���ʐ�Z��� {�$3���1�8��S���cd�>1M��j��!���r��������D��!�X(��X�NO����Un$���rn�P���H�w:�f!��$��;{/���U
�����H8���t�=>�����r >FƖnO�+��$�	7!x:i���t>>�������`�����1��n;gh�Y`߱,��@4D�.'+lJv \��OV8O |T/9O�x:��'+�����1��t >>�[�d��q2P=�'3���D�l�n��������p �@�HO�I���"	����t����@����\���d���;��0|��e;�� ||���d��ph 1(O?Y� �]<�M?Y� <�Qb1x:����i^�;YK�B�^����s�6�K�l��G�6�K�i���M�����Mx��/y_|)*2æ��v3E�iS��!pք)O�}�ȷ�<m2�l0����#���G����p>^jV)OG��eH n��s��RY���)OG��e +"�tΆ��<�����P�d�#��2��x: O໨1�J�w:�##��ܜ�;~���^]NV8�}�Dd���${LZJ�w:�-���.;���Ljj���T*�ܛ:) O�� ҂5�� ��4R�� <�3  2!)�N��)�~w
:�� <���yS�� <�b^�;��#p@���p6ꐆxx: #�t�E@�<���S;��ON8�C�|&�N��	{���F����7)�g*�w:��
학�;��A����o ��~��8{4H;I) O�cdl?x: +c����x�Hk�{fٚ!�Я�^Hx: ��IZ�	��8s��H ������9�� |�$�Jx: Or� �&!x: �� ��Ix: ��D��+?����j�]��|�ԥ����cf e����r�����ܚ����|�I��B�t��G%���C�$����`��G��eHdSR�����@ѧ<�����4N1x:g�N�����18%��!R���YYH�8D��<��QkBxw������3(`������T�D��|�ԧ
"U����Qb����|�����SE�cp�u�B�r��.=���'�=RC���1���[�S��cp���x���1�8H�]%/�T����vM�-xd�7n���¡tĮ���Ë\�����[�C�*^冣�"��ǐ���h�_^��rΎ2҄U��r�����D��(�ȅ�g�.ax9g��~(Qx9
/ʨ�N�N�]�kKP��}r_On8/R��~��qx�
_*H�nr�a8i/�z^qx9'��Of8'C:uw2�q�8ҡۓ���ɐ��.�vNIb��v�����1$6�kW\;�B_�x����%�T��>P���qx��O9e��k���6�jW`;'�?+3�S�1�]��8|��]���؎Ù����J^��)�A���[�MY6b*-ax��l��+���-�&	^��F����U�|E��t��P�2���S�[�M�v}�vJ^�^'�wJ^�f�8N/Ya붩�&��J^�v��ma81����"���_^�á����p>>��0��Sx.�=��[4O�|S�:�䅣pjJ$����r��>�ߙ(��>��A^����@�؄�p^xS�M1^���Q85èY�(�����T�W��r�X�r_Of8'i�������G��v��g8�@��n��a��H[�%/���ң~��a��h�|��p^�j��O^8
/|��*/�E9� ����Ax�G�B^���@�����p��v-1x9�����c;�L	�J.ʜ���p^T�_����CpP��"/���7��(+!x9/�� 8����1$6�J ^��FKד����]��� ��������p�Q��������ʥ����!N�ܟ�]�r ^�#��r NbP~���12��~r�����N����7U��� ��r��4�T]��r�]���ur��7u�sr��X�XS^���&DZſ�d�=w�h(��}�͙�J6��"�v>N"�2�t���xҩ �  ���n����(����9gM�؜jx;'3�TD�B�v^���	�E��|�����#�"����9/2����#�2���z���4ܡcQ�$jx;+��1��#�2$�&o���}EZ����9���Y�~��!8|�B���Cpxh����C�13������Mg�h!x;3��������D���ۧ@�	E�;�������⦟�p�uZǛ�M�<8�2�E��(��k�C���vNq��Ev8gB��Zގ��<8.7�� �)FG�-
oG�ehm��v>V����\{d4U���@-o��S�~�1d�������!o��d����v�d�S�¦��p�*E�9��&3�7���o��v�T�����{�v�i�:��H;o����"�On8'�ế}R��-(k��ާ��s��~^��0�90M2���ާ��3�H��z��v���$]����i��E����v ޟ#Ԃ���=H�����۞���i��m�S�
G$gZ��H5g�?����G������Ͼ9yaOVs�ח&o{�G�����5�����jqx�s����Y�@��Yk ����v λ٪Ig�����@8�"�On8��DZ:�/7�7'���=�x;g9�8E5���	ؓ���v�n�á8F��Z��Cq������Cq�9������X��px\#�X����я}���`���H�-o�T�#MCb�v,�yDeY�ۡ8fIp���X��\�b���;؟�l���z�x;o8�zt-����X�uj���ߋ����@T�N?y�P�0ReY���x���-o�䪶t2��8�	�[0��)G�͟���q��*���`�)F�E&����k;�Zi
���8�VF��	���8;��� ����p|���������)H�K/o����&�x;�Z�p�,o���c!�i�x;oP��t�I���p�};������&�|���?�b��Q9��J�c���G�^N���x��W�)�������@�P�h�t4�o��G���(�9)�*K�7MD㧣�q2ZD��}��8']��3*����8��!�)9E㧣q��Z9�~��G�M.��%�_�h�t4ސ8D��ù�O�؟M�wSeC����4��?~� <�1      �   �  x�%��1CϨ��ƽ��:�ٜvmc$$y����VX|v톎6������?*��NY����6!�?K���3��z{c����Qq�����x�*�a`k�s0'l�i���by�[n��mr?Hi���KF>��ɹ	�v8����5�Xm��i��c�C����JQ�M�h�b�B�]�a �ų�C���*X��� �}:a�����CKJax���@�{��Sf��������!چq0���2��� �B���s�É�	>ʤ�!�tF�t\���p�����-��&���0� �b�Q��F ���������C�P��!X���d\�w~��T������mh�'Gw�""õ�/��nmhq�i>�����V#�F�� ���R����H����F3)B�t�(Rv1��=�R�wBd�φ�Jh�b���/B��"C���"�B�����B��*��G��9�9O���}��/���GlΚ)}����-:*�Pq6�]���`���1��F+ʀ	��{(��l�ws@���~A�߇��d?8Y�8A�O���FL����]�(Hr´)�[�y(�K�V|Hq0����3*��KN��� 4��#�B��      �   �  x���;n�@Dјo%3pa���G^�����TL������$�C�>6���=F�5�ۇX���G�?������`\��'��"�>�}.��g�/&&K����-�9�ő�\��%���z�\�����q�:8�{g�������I���u�ԡ��!UÂ�tJ� �J��j����R5h���>�@)DSǓ5������0*�|6��S�X>"X�9�
*1����F%R5�X��ĦT%6aTbK��[0*�-UC�m�ؑ����J,}<yC�]0*�_UC�8��J�P�
���k(q�S��ۄu^)�N��J<�T�S���p*�%UC�/8������7�J�H�P�N%�>����/8�Đ��$�JB�j(	EPI�T%a*���`%�*���`��������R5��DPI,�Jb!�$�T%�TG���8*���4J�BP�R5�́�J~�}>�����      �      x���mr�8�D�b6�/�or�2�_��z��PE��b��m�$��t�y�^y��\�����ם�J�����r�����ۯo��}�O���M������8���׿r���r���+�4��~���/�O�j�Ϯ��KkH���~� }�}�{]E?^�B�'��~ի�+�~e	�����������>K��H���3|����*���ٯ������}���B�Y�vmE*P����S���:��$M}qb��Ő>�H�o$΢h���	>2��vMM �̨&$�"J4u��^
p%ɢ�k������)�Br��D��;��
u����H�C�)�rg��N2����trI���ęR�i���S���v����O�Xv���9L��D�}���=?L�� ah&�[�s;�����c
��� ���'z9u����Sv��'*�yL���Rt�Q���p�A�1�h��՛>Q�̍��u�R��>�WC�Վ^c����{��$���#'�Pe%��5rt҅.K�-�G��-�d��I��OT�x�C�J��3Emea��r�^&/�����C'dm�D�_�H"Y�f�N�8�!��$�ǿ*���]\#�E�m����e�h� �5�wS%a�ܖ`�V�B*�+���#���~k+ҭ�?�CG�\��(:&<��Ԉ�-Y=��,�Sey�8�Q��i!@<y�d�F7¥�L_n��ف�O¹�X�<�鼆?��B��y�Tu"W�%���-�l(A'ZG��(E�K0-��n��<�z����A��9ѐ�a?0)m����>&J��-3�h���'� uuH�@U��	cdUa��O���|�n+vwѳ����_�W]�\He7@�X�bDMQk 0m$u�Ϧ���m;F:�`�ڗ�F9H����pL6�S�;���&�6F������;0�b� �0A��<b��x5_r�;�KK0<z���5�r�mk~j�����}�c��K�>F�	cc�Y�ݏU]̓�w�w#@�E������殮H��D���n�v�;���Y۩T[CaD5}(f@��~1�0��fS�f7ӌ�`�����]6�.e�����sPp׶QLaG%��/\�JFrd����#(� �{��EBX�0��������0"WI@���g/���|�C
zh(f5�S,��Z$A�ljQ2AF��ַ��a�;�4����(&��;'`\M�����`��B�>�wTէ�OYw��d�H���;J�mӠ�,R3��RA��1����;��p�TIV��/6Ԓ���B>'�[�RX�ό��=��ԣ	���(��'�zÉ�D �Ӄ�wX����H�9 �O��ɬ(Yb� �=���!˾wļr[Q����\�QY�8`�P7�p`����2@�9@�΄|?��H��c�Y�)�?ݕyǗ�A��b>$`��Mr��4�`O���9���Q�D�p9=j����-(��lD�=�Ɯ?� �����$T!��E� ����qY�a	
����Kw���D(E�[|�� ; �P↞_�0�~f���,�9�^��C��9��{���ْ�C��1f�e���Lc"������W�$�}M�x��u���7�`��~-�Y����ig�tZE�3O�q��VԲ�d)�EJ��l��x�/,9���,�<��J�8�l+��E��b�Ʈ�F�C�k�I�ͯI$H�V|gQ��e��B�^��f����^�G�3ٖ3�>JU����lS�a���yƴ�_�3/ޙ�������*k+$7�#��v���~�#���,�I8[&�j+)��L�F���n�nz����@� )pG#������ �w�tb��H�&��=_�6�O��n�L���N�Ύ��p��f=��j_M����8r<�:l��*7H�Rd���J�X8O~v��8��/k���6�NTf� Ř�n�Q�ց��6�e�k�z�u��'h+kG����V=�s`dR;�n�N�5=��W�C�e���T��/&e<Ȳ�IM�4{��Y�X��*�B�F��Pb��L��&CZ�����`E;b������W+�$�_$�|��[�!��rU�v�B���-m���<�^��8��P���þ���Y��Qz�y���W|��㏡�)���7��$D�Qدz�wp��鈥���]Z�| N<0\R%��Sk'�m\����.��9���/T�¥��q �$v2\a.Y���ޙ-r�DK�'s�-zN���|ŮW_W�*�A�1��/���t?j{�2��<��H|��u>r㯘��nq>��:������{g���4±�;�c�[�sB���`�}	�T�u��Ի�P �E£J����o8�A_�/�'_/r���V)�ˌ�X�`	�u7��|N�@.alS7�I��/?>�۱KH�.�1�Xn��-v�a����9��&������k�������;�Hե�R+�`-�,�T���5Gǜ��a{�\Q#��O@�c��:�b#�ޛM��ƭ��8�9�*�A҄�h.�s�e��nr M��y�t�ֱ���ҮS�{o>�s�sa[�]n�ͩ�'\fƵ�un�M��<GuRj\���TW���?��f%��eD�g� J;�
Ǟ�:~8�t����ȑ�ws�`�9��r��,
Ѳ�C�s��GJ}u':�:��P�&�����T�ɞ���2I�¦6���m��V�)�ц��=X��!��`��Q��Z�&#l��ܥ,	��d������o0�M��9�tP��TW�vg���e��du��m�x���6�6�s҈�lik+�.�Fɸyn�ݲe�P��$`ͻ����c�
�����=ah�b%
Ҵ~ۈ�TVH���d�yQk��v���y�������&�H���(�1΁�Y��<��(T4���z�Ǝ~��J���gQ&Ū���=tH�}�L�@�q}�����t���HԼ��� �0�[��ø�Ӌ��w����w7J[c��.�F�B����b'�)F���@��	v�7v�(@_�����F�=�L�
��L���s��I�r�)��{�Ӛ�w��+��9�(V�d͓ �.t��q���R2�>����Y�)�>h�q�T+���Գ]1C�6+r.;7(yHӺ/V~��p��OKgw��a�{����녤�.�#�|�;T�%�f���v�>è-[��O�rw�uWo|��V�� ����*�0�&�J��]� �m�t́=(VtH�BB[���U��+�]�8��5���aek��U�R�!�8|��I�����ն�ۗ�\�n[�4M;�K.��0����K��e�Qx���Hh����g�p�R�@�&UA0޵����Q$T<)e���y&F�C�7|���$[��������{:椛�X�1�=�{��5>V�J_�|8R����B�ɬ�(H&\=lK�����Ec<3tp��o=u�Y
#J�Z��F���L�Iyg�����;o�0ӈgk@մM�*�4<f:0o-���F��*>����R����@��t:�`e-�7Fe��#�s��������I'w3c�w��6��Tv�}:B�c>�ϫ��v@ǰ"P���?��X.��l��}����F4��/\��n*R�>R?�$Y	�T�1of
�O$wK&�ƪ�S���y��-qK����ˌ������li0���)� � ~}����|k��T�t�r�d!���2�S�2}V��%ӂҴK/�Tfz�ukL׭���S8c�����NkT%�3M���-4Y6A�������:�F/1j��Nj���D�=K�iEc2#��K�R�K��f�H�D[-��{/|���:D���Xr	��E6��ȟ�4��������!^X�h����:O�m�J�)��(4��k�f�H�g����|{�{RI�c$��4�U�'�����a�Dָ�:���q����	Ok�IVK�R:#L��ʅ�A���>�p ��^V�A�=5��eFrZ6<ۘ�0��  �e1��ʦ��xO(�$i�ߐ�Ma{mf�ڽ,s"�G��+���XO2Y+\����<ڮ�j���f	��˜��@���*P��p���o �  ~9yP��J�u-��MZ�f��"k&
�QkN?9��������Ñ����y��`Y�gnnh�H7�ˁ�F9�d#*YZ��Ħi2��|!�ER1�B� �_���,��H�Eckz��7*��f��0D�7o=S5o�H�6Wg����Q���ǻ2�	��^��s�Kpg�2�ws��: $���k�7ڜ���%�de�7(���鏫����<��߼�նe{	D�;\���/�;�%on�Yв�u���V��Mz�3����-ky��B.B�z��nD��$�xUH�2���ڣ�����sN�O�*##z���ٚ�Wk�(�@�%و�����S�d&x'A�K��y�L����X�A��5%�w���������/��C����ʏ��e�v���UJa��#�F���D)��:`~�Dif5�@�P|� v4�uQ�]�DZ>w�>cd��b,ǣ��߹��_���o�&{���$�J���}��������������}�      �   ,  x��Yq Qþ-0��;�R�8�E`[��p9� ���V3V��'{��s�c!,e�����56��V��������y�)O�䅷�����O~�S<�F��k��"I���V41�!V��)�|�G��HW:�o�72�R��&G9�*�<�QO�(S�*�BT�>B��Z�Ԩ�Z�R�:��mj�]�t��Nuҥ��~���Ы^���<�cLc�k�	M0�I�4Ŵ���f5˜�ا}�i�u���6�ɖ���6;���'w���t�3�q�s.t��.��׺�F7��g|�����9�?�SrW      �   �  x��ɵ$1Ϥ1�
Ђ|���1�}iZ�������VGޥ�NiG��}u�-M���*��:ʌ��bQʎ劜�ķX�����T��q�
�Ӫ��*$^����
.�x�?�U�cv��X����!ߌ�vW�Qj����>j�0����eF��TNjQ>:�c��
\5��j��--r��ѭ��{����!G�㰠���hq�$h�F�|�/x���A�6�����W�H6i%^��G\ݏ��M�1HP�e�+�s�܋�G$~�a�.�,�{4�"5�e:�ې�Os���AMCL�y[��<�O�"���fǔ�;�%|�H���1Q�n�����`��!2��)ҷN����d���8��2|ƓߊA"M6��pلZD�Ǣ5F���b��S��i:1Hu^���U4@��+Z��?O�B:�Z`K���A��g¬���)�{�����m��#<��������:0�:���������x�[�|���0�N�OČ�"�%[1�q��}G�����]O�/��)�3���r#��+t����U$0�xMӛT��y�P&D�����47��{�5��lk ��	��M6��M�|r��L7�7JS0����|�i�i
M9O�f�?f��t�a�yiԉ� ����5�9q|j�0p����gܹ�������g      �      x������ � �      �      x������ � �      �   q  x�U���e'EǮ/�%�0�K���=���W־i��J��U^�\X�?���_����O��|v?����������}�ϳ��v����lٲvW���ٶmm���?O����3��Ӵ���>��<�vyzn�?O�=����[?O�0����>wy�X�+,�dӍj���.��0�yF�,�eT󷺿2��F�����9�1�E��L:Ө;{�2�F����i�3��{}�2���ی����Ө���kտ$J�-�S��0��}�2�/����Q��mT۾��2���^��]��4��}g�ׯQm���+��3�����e�F�ލ~��Өv��g�yÍj'���o/������ʼ��j9W�Y�mT��=W�7�Q-��yʼ�F���y˼q�j�n���Ϩv���˼k�oj��ʼk����2�r�ڽ��-�0�������'˼�W^�]ۨ���o�y�1��s��2�J�ڻ��+�kK��1���Y&^ϖ~���	�(3�a���Ag���4�NN:Y��n��t^�|�Qm�lA�̾�Qtbщ�g�iiך[��)��c[;�L��y����{����0�׶���{a��m1������;�C��Oap�1����q;b1
�v� ��Yv� bg��80��{7������
��v>;�������v�`9V����`�va��r|��,rZ��z0X�0H��=a�ga�a);`��0�e){�`�� ������AK1�g�3�CL΄��� ���$�U���apNap���9�`pnap�]1����u�b������]1��\��]v� �w���0�W�cW�����M�bp7�Y�a.w�����>�����fa����9�ap_a�=1xo����(^���a�va�=1x	���������}������y�xa��(:�tVa�Qt��s�� 5O�|t��Hl�1�ͨn3���6y۬���j
=���:�@r�,�W�^5�9�!��OE���)���W���"���]u���1qϽ:���G�ܫ鱟�B�s��=	���B���'��X�G���O��1���ŗ�I�>�ҿ��?	�� C
_(	��B}}y�DP&�d��\$��A_蠯/��A��儒BY�/��w�BN Sd�p��yKL���|����c�GJ\�c�zh"K�%*�.����z袟ꋼ���C9�*�Q��6�����g
=��Ouǉ9*�;��Y��s��=\�:$WS衑,���C%Y��
�,|nOׅꓜ��4�k����T衕~�Wr�B�䘯\0K�z��%��)�PL�19�M���f���ɑm�n6py�59�M��n�T.ئB�d�\0N��@;Y��Q�H-�PO���T衟1�N�S���"9���CCcT�X���YM�0�.����D���j���)��Q��U�a�,�>��p���r�HzX)��S�Lq�kf�҉�*�0S�r�Kz�iDuS��n��iD�S��z�iD�S���l��PQS��,����XX*K傣*��T��KU�a�,�����Uc���[pqYWW�j�WU��㫱��r�Bc�]�u�
=�5vuVL���Ძ��Boe�\�V���\Y*�U����T.��B{e�\pW����+/�)�0X���ۄ>N�KⰑ�a�@S�a���b�CS�᱑�c�DS�e.YMw4���eY*LV��ͲT.��B�e�\�Y�F�R��
=�6nuZ�Ӕ��rS��
=�6^|}�чqy�m�j�ȓ)�p�x�m'f���\^�[�֔�~�R�`�
=��r�oz8.K��*��\���U��kVϝX��C��.��)�p�5��NLW����y��i��S�]�~}�҇��l�Ӗ|������o�]�      �      x������ � �      �      x������ � �      �   �   x�=�Kj�0D��a�[-��.�d`Y�@fr���*�����d;���c_����p���f�ɱ���1����h�y�ms-���7�3�@kʜ�O��Sv�zs1�7I�����.E��K�Itzh��4\2\0\����
/^���mn7��s���Yz@�8�P �A�@�P�@�`� +q~	T�tK�%`���D��+JMKMK�[P+��fW,Zt+���-bï�����Il[G�p�u���I��      �      x�E�[��(D���t0`�R�G�Zڧ*�W�6!�R{��zϸz{�������s����E̓�]���i߫!��z߈������˷�����ǫ�j���Ϋ�)�kF8�8|�^#����_m.G�-Kx��v��_�=��Kv�|z���Yֳ�տ�pf�ye�ƨ�o��\i��}e�gE�jzf���\�h��5�留2��>N��&{�,;+_�(�׽Ƶ�9�+�ʞL���|���(�b���-f�6"}�E(��l�g��jG���5��G�������_�,���6ǕA�DԳ�m\¼��a�����q���`g�'���MTѳцu�-*?npeI��x�؋j�����I���S~���e��Ê���u�09��,��\�,�C��_�����,=��[���:cs�X�����<nϸf�$f���摙n���푟,&�D��g�C��\��F��L����� ��&Cz�,�Ůb4{E�KbW���L�E�n�'�y���F�Y�����R��	z��±�)�?�K�@�"=�̇I���bV�4�m��:�>:���_g�<}5�>8������������ކ�M��xs
1�|Ʀ�=G�Th1��bңs�.�ƜGt�ab�o��E���g1�ߎV1p�1�DW׊��7�n���'�d=�@��֬�~��k��h���!�S0|���_>��c&�mP�ebstq��c��ߵ0GN���%�c�ଆ8׳p�;��~_l��� �|
#pV�G�!W��%(��}3j0�\�I @���i�N���a��"����p��?"a9x��AFMgt�@A�ի�����*8"g��}�R{us�i�䱜,����H�X9� ;P�g`�Y��h�iJUS.`���M��]�Q�9 9��"� ����]H��ɓ�
/��2�u2i0N )W�j�h��v��[�bq���dȗ��Y��0�W��H��YI��O��76�fe�=�U����������ypI���vʽ���&���b���8IW؞t{t�X�� 0�@���"q8&D���@��8n+ϒ{v�)��8�Ђ���:�TGQ�D"ҫ�h'�HX�M��]pDN�w_�����MD���fNN=/��v�,mM�i>�������w����{"�p	%�Hq%�#�ɳ�G]7�K��2^L�Ff"���VxCxb́`��-��lŵ�C��H��`���,+��+|���)|&�Lx�)3�����'Ƅ�E��1�؉�&x59���(�I�|X�k���2PeD ��h#EA��yt���9��A��L2�鳦����B%�����`Ɓ"EeqE��%w�ۖ�LP�Ib�w�(D�i9�8�%����+8K>�� ��U{�C^��Q;�1>��#���.:�9����a6O�nj��"ּ�A �`�c�x?W��ah�Ƞ��T��	>�	l����b��fpܿɸ'xM�O�E�Wq��Mf�@�S���g02BTT��1w	��]�>�)Ė����)"�Fa8�,g��r���"����4�Ǭ�?Xd�	%td�'g�qC���a3 ����l@E�ldn�� �q�BG��բ)\����'�e@W���*�Z�#m�P�c��BkDU�x���+A{~��>�!@�X6V�Ŭ��P�]���������QYP�|`���l�;���t����#q�YI�<A��_
3�>Ch�'��caf� d��A�yB6�>���`���	�K�\xX�E�)Yg�]��&���2�"0�٤]'"��u="H���F�-�s`"4T�`�((��5���C�t8�!Ga5n�c椐Fq�<L�_��Z3/��d��-S��Ҙ%+��X�jX5D��⑄��l�W���@��� �{1�Ջ���9�sb@��	���4�_]� ��d�F����%J��N��9�%?~@[Nh4�YCO�l�l*"+�����"fnLk�<�V�-�(u��f<��Q��(�-F
�%�Y0q�����mG�A��ޙQ�ЖV�`�(�hբ|ы�mD�g�i�U�Fʨ�9�9�����p�L3��HY��y����_\�䱤�/�mm}V�ٛ'�g�V7�g+���݅������Z?�N�ɤ��q|�d���.��i?�\ĥL���큵Z{D�k��Ɛ(Z�4O;��r:�=J7 �K�(���G6t��������&�[���@�n0#X�j}4�ތʂ2ǣ�$�41R��E#�t�d���ʁdƀ��V�
D���P!���֞9��る��"��WO	x���e�ȳ��U�tVם�3��1\e����Q���/Қ8�tb�	ȋ��/�y�f�d�蹋�0Ƽ��C����(d��h�W$��Tb�e�8�sC\��?d	Mr�P�;�JA���MP1��Q�2u�a�r�)OHB6*����C�raДL���W�.���;pe.�j4|s@����"(�"(6 �Й��Ƃ]m9�lᗬ�>���2a0c�C��7[�oV`��\P9�Uqpw�ʵ�4�b�GI��P���_e�i����oʋ�(�mU�Z��L�H�0g索�-4����
x��LW I�)JȆ�6�����xB�Ȃ5`�	�T�}�n#�����#/y�,�&��`%��F=����ٷ�(7_4��n1&[%�r1Wm
�v��ԧ��l]�a���W
6Q�|��K/��@m���◤;�·���U�"�R����D�:��ٱb%�ŰЍ!�#�����-@c玡
+f�7a{��w�";ļ�R8��"���W( �3 �B���n�}F (�ϡq��9����5с�_&��o,CϛZ�&�N�I���_೮�������,�x�. �`C�%B*N� c�& �٘p���s��F�����`��U>r�c^�y6@���(�V�4V��XS'D��Q�A�~9�S*R��,�j��� �d��Qz�	�I�k���_%��e�T��\7��{�1[+��g��B��4>�JHag�:�- a�#�7�Y%$t����4��<`j��nLO\&�E�<�:�<�8�ڲ�F?�7T�����EECC3l�<�X[�����t �V�����ej�nu7벣J��J+�(bK�EJZ?�@��=��B���q, ��HpZ
t�|���̙���Te[9��UX�W�N�$�=��X���?�r��Ay�k�u�(������)�WM�<�v�������cXM!��*�V���X[��pK���ݖ�w+���yj9�qb+�NR��?���Ē�
�����2ū����>7/� 9���(%��Y����'�~�y8S���X&oY���M���̿�}�G���c(�D���,�tW�q����Ul�G�p�	 ,$���d���q�J�fcП4�^6,'CZp�L�h���߯�:�=�)�1])�R�I�juLX�������V՜�rP����o_��X����@p7k�CscB�Q�bˡ�mx��"'A��eG���A�Q�9�gJ��� ��A)���-����~IՇ�!�1[�1.n�O؜�UZ����jh�����Ş�[��EBV� ;����JĘ�����j��P��_��D��)�nX�6�fYϾY��t3�i�\%%�8����J��c��v� ô"�\�,��B�nu�R��!�]Үޫ�Ս~7(��nKR��g�P�ޫw��-�����0�eA��7���Li��~��ͣ��B+�7@��S3~}�-��������l��ϧY��x��n;�@��[&�TŃ�z=`H����������:�7#����o+oD�<��j8�<��ZM��j�/K�X���lZςd��҂9���fu�}V��9mE�26P��)u�i���N���0\�[�I�@e�2��]�>�lV�٨�F�\��ۼc{)YY|dq����Y���b�Y�.0%|د��P 7	  a��jK/O���EfMC�$3�����S��&Q�����ԡ�hCk�JK��U����D��ٵ��I�˅��>AK�����`�|�_x+�D����W�5[dC�2J��Bl�� p�n! s��^�Lz*I ~�<�U����|VM�~�F�s*Y��ʫճ���f�q��O��8U���.�miՔ��؃ߕG���5p�[6��2�W�U��ޑ�B��M�OA����ay6è]�;Z��{������G>S?^j29Nn� ��C?7��>����r�9y��W
�e9���O��!����z���`�|�]ʖ�:�H��q~=����i�P��x����O2����]7��Ώ����qY ��תr[��e�c�ͭ�wL!Q|����|����{�+[㊣`�^�r�Î�T4��v=�4,�˼���c�êe�b[VrM��(��}<��ԱO�e��.��2	�if
�#.[/�"l����x��1�C�B/��mX����Q�?�Z	����dd[3�f��2�Q�ϗq���	l226�j�R����V�Q�p1*D�UOaӧm�[kC �ҏ����%���l�:�M7�XI�)Ҭdn[?����<��j��IY+��@G��U�|��mi�s�0 z�	����A	�e��GeE9�5���J�lV�먌`b�C�e��6?�#�Um���}��-xjV�#��d��;����HE�gHJf�\C�o5��W�6�e��nӱU�������5����M��C,�&�@�R���<P�*D�Z��kD�3- 00��R>AkK�c�����MO:({U,�����sQ�ث*~��
7)��&�oL`q/`0ȴ,��7�U�����������W�$������jֽ�e�4R���(��
����wW����yS���2�\F���~��h�{<Z�s[%&��{��ö���H��\�y����UM�Z}�2�� ��	E����{T���A�Q�n��"ڬ�� �JrF=�8w;W{Eg*��<��%�\��+L�M���y>|KٲT_��ұ�r�U��M>F���S��[��ؼ��=���?^��k�U���a����TIwq���S�����k�7~�q���K)>>^°���]��g �[Ws^߯5S����r4��
 �#��+�.�����A�-�]U��o�#�FeY;5f�������Ś�5���8*�٦�:�NԜS���.���Uw�0ُ�ү��}�����$��P�}��%;���GJ�(�{d㟀��ݏ��E��MɷQ��]���5~J�����m��y��-D�)�us��k����O?�(,�j�؏��V������9;.��G���2  �7�j��G�Twoޟ7�/����{�*�P"3����Uv蒯��,N,�fս���9f���&/o�퀡;{��ޡ�tl0�J�V����]u��,�n�gT���U��{��n6S�C�17|���-*g?p���j֯�cM��^3[�d���@�#�fJ�.Vc�ص�����3i���u߈�_n3K����3�/ZǬ�Na��UZ�5���j����I���~�`I����y��u�!Fӭ�q\�dE�!�W �"J�*�,~���]���`3e��jb`�w�4JF�W��Mn�Յ,�J��<���d���K�a=5ұ�-��Gd��ܐ���}"�l���0��J�#��9��4M�ȶ<����p�w�n{�F�H���x'�����ŞVM�^�`��}�K�
�h�"����o]�}U��V֪>�H��{	;� ��a֯ ���f�ȁ��a��x��b��i�xJ�&+�v�m"V��ﻳڎU�:h�W�zyY$���_�Bc���j9�ڍ��s� Gۈ͇`�/��<��^[��d�^zf�q���1�SD�L�m�Z]
Ȗ�%=�TU3Zփ�/�c׳�����W���?�P5�|�v�v%Q&�+i�B��M8d�*Ƃ����ᓇ��ӑDyTV��g��%U>�Q�k[�A ���;����2�S<-����u���Q��ٴ}a�0��'��-��$&n�e��Y:|y�nM�j�H�Il_����aiU*�xz6���	��DΒ�{s6T�I���+*|��g��[d����u�����~�19<����7��݂�7W�k�q[����/��f�{��S���k��O������PRV`y�y��-�f�LИ���ƹ�ɫ2^QI�]T0ML<�ȸ3�y���%✲��D�Uu}�|h�?����V���AT$w�` -��Ȝ;U��}��MF9K����B=:�0���Mg��w����ߦa      �      x���Y�9�D�C���3�C�������R�h)¬�;�.��S�r�r+W�J�RH�����?a�7����O��c���v��:���ի���X~�~�g�������b��~
N��8D�b�b�W�j��،�]�y�5D��Uƕ��4V:�ĳ�\��r�yiS�SH?O!��Я��Mf��]qo��0^��z��=�8��r�~�үi�x����k	�貂8�+m�~!�F`5J�_V����w!�K�g��g���Q<C�(�!穓M�p3�!t�B�y�+m�Q^H{��:�jG�#�}���N�f�S�a%�Kl���/���ǯ�Q�K�'i������y�g�~�x�[t�IFZ����	���~�|�ve�Wq�|��ߛY�z}rZ�<��*��O���#���r���3^���j���Ŗ,��vl���=�v����ej7�x�[g U��0ZQ���@�(XG՞��uhdК����vŻ�.ѫ�{�����{G{������^���%�����1�������6b��9�3�7l�IG�f�D��\f���{���k6��rLM��m���@e��q?+��ZD���?�zsj�<M6L3���$�{��cZ%��vMw�(�B̚
W�s:^ˈ�P�zH��,do��6J�6C<T�5���0�d�Kx�H$��i9�����vu�Tu6�����G��Q�:��mt<��5NVFV
���3؉	�*�7��w���A\7Ȕ�V���xNlVK��C&�?�`��be� .� aHAi}��1���g��)���Wf'���Nm9��X�����k5Da�f�Rܱ��f�ʵX���� �yh��.� �_���������*5���}�ѐu��QmH�dg��%lÜ�|A�۾d|r��Sf�z:~֋)ck`��Я�}�~^�\J�J���g2�3���@����zme_2[P������17��@2�P;1����h`y��`�	�nڷ��v(p��d�Għi����I�0.����y��4���E$�aҏ�]N
�\*߮d����?9i #�*���"�>�Ϥp��m�2��Ɏo7��Ӻwro�})���k"5 �+���_'�����t���9c������b�>�P)7�4-G�L��!v}�c�ٲ'��N����@:l�Wq\���r�8�~�.���w MeAW�Za.��=��X��+�&�W,~�''`|%�2�=
����H�:�FLyA"|.n�\�Z���7O�턬=�&��;n%�2�G&B��<{"?�R�Ve�	[21 a��b[u�<�vB���3���˧�1��O�д>�3�s�/Ȥ��CH��D:8�96���=!���PpN�vʤ�f�W[)0T�7m,��(���X,�p�� ����U}��t|Xj����^�ϡ��*�(c�'���	��.Y�BW~G�3D��0ml�����kk9�V�q\L�^��f�q��w���j+�H9�k�湯d8��>�h��js����"��B�Cj�8@�o���ej:�\�hH���:�Б��0=UL�i��	IJ0p�1�@@��6��Z.?���{�蛭�):Y�0ou�������cl�>��lE�l�5�[��Q� ��җ���{�Q^b1�&�w���.�"��Y!��F�L���p80����5�/���A�����[�[,�@�ȉo��]��|�7wu�xcjfO5�0�IX0��^N��g�,c���ځ���[��"�G��}n��ڊk���"=�͹.	; ����pm�F�F���[�pZc{Fi�Fr�_b}�M�e6���=��&����,jW�ŶW�m���"��@.v`�y���lH�g1Z��aM��S����r3#��w�� 	�z@�0�<ܴw��V̔�a�Y! �V	��A���w��Ȓ�`C��s�������#�[)�2��<Et��R������H�e/}��� ��
)�����E��"�L�z�D7b/v����Ju�~��6�m�+G+�E��(�I`d"e�x��^���ܣ�is1�{���II�;�+���1\8r�V*�0��[
5l�[5C���A��';&pG�����v�x1�od����7E��b\��l���$����m����e|��-�Za�w9�����T�)�|깟��K���� ^�nΕ�`���Rp������r�'�G,��l�Ger�f腭&];ƩϒL�}5�0�?+�Ur�ӂDeG�ߑ@��4	�Lu���<B�,���-k��fVS�Z_���V�
��������t�7�-�'4	�r/>~���XK���|e�-RX�?��
��oo��p��%��q��ԇ�m��এ�G$<8n�[�;q�]�-�gDL�2��ps����I��àK�EM߉cał�)1e�e�C~�<jX"�j�
�lݵ@ߎ�Z(&�Z�V�i��P��k��a���aÃS&���HȾ�����E�I{�L!a��]���֘� //�UD�[5� ��h�ʁqViB�ZEغR<��r�m��hF�Y<#g��j5�a�|čĥ�c��V��^猋(a��l�E�;��s9��#�
3�bG^�Y�_w�pp���Y-�'X����T��`Z����;ֲP�u=�s���V~@א̣�+��P����%�}M6I	Aݣ�7~��v���%�ͭ2���^�\�
��x:��i������P���ap�f�^�<�]�E-��ϔ9�FXE["����Q]�a�Z�[�$���jM�*&C�&�Q��G�}�ǙJ ��x7[W��:Rx�cf�5���߸�jEu'���1�F��U��Gn?5n�F�'V����	R�%Vr3���g4ƩT�Y�\�����5���B�k�n��$��Y��8~��i��RF��
����]�
f�i��~��V��ne�nvp�)U�w筘�v����ۿ�J��V@@����oڼA���N�j�`~�P\�&�Nv���v��`9i�2Q�k��_�}S�f���y�""ķ[�Lĩx5��f0�m���P��>� &s*m��}��@���F����A�9�R,���h�^�;�X�k\�FKm'\�r��p#TY�^��vL��In��(C���l.�	g�jV4��i��k.�8B4��uVm/tf�i*Օ�%�66�ډ����f�Td�{I�l4����]�������#�V͔�-��3��@g�<e�	�2���z���,��EH�[w��hj2
�������K�emY]�ɖ��@�ZA�c��2�q�Cz�q���ASv�+�̟�U��\���K؟m�Ѻ�V��6ݚ�6W�g����I��{������ێ1�k9K�ޑf�S���Q::�d%�ʦ�V�P����*�$wu;ˮ�pF5�A��ߗ����YtF��byoI�Od,}=7P�x��\;��=��۾i�Bi3�o2��2�7W����#���`���tw��d�5��IB.}o���az"�4�\/���A'�g������}�ARJ난�.A��w��A���� ��h�����ڋ��g�I�P/�����G�ڗ�-������-��@}瞾�G�&�%�A���v?����B��F1�Fq7Av둻��M�N�i��3�kh�n�3+��]u`+u��E@a-2��ło�ܭSn��
I���:��%ˢ3Ex��0���%���fM!#�"S@.�Ke#>������Z�����7��l���`��(]�1&|���'B��5z_���޵$3ź�e��cI�5�Vڷ�U梨��Ln�2l��N�{�N(��F'�[����f�i(�$�ww�-�������?�]quⲥ����a�aъVî@�y�oR���%K>a�^�����4���� Hx�C��h���̴*��a���yZM�A�2����F�UV�·��{��w�9�u� 3cCe~���b8P� �/��xÞK��2}Q4����6��kAY�؋���?��Z*�a�!co����#�&v$4����~�8����k�b �  �`A�d��F���p��F����jMM�y��HKβ:;8gnr��q��k{����2j\F���u����	�f=Z�b%��n9��V�5Q!��\��[".t��TQV�h�˧��gJ��P;J�����zu �G��{3vuׁc�녏�Ɛ�n�� e��T��>,�f�]��]Kr�,�ꀌc����W�+Q57�=a��4;1T'k�R)(Z'��j��S�g��������	8qAV��W�Pi���٤?���̤�;J&��]���z����N�\��NAm�}2J�Ǝ)�3�a�G���F�����1�$��e=�ػ�q����nU�u+��9����䮱�
���_ӽ"R�%�
�]�v�p�i�0:m��q؁O���,��]GMk?��0]��a�4�����Ѽ�c���a/(Νj�v� E{:
B��sP�(l�}�U[�Fq�F'�w[���b����϶�#��*����v��-뚼�U�Ʋ^R�1��r���4�6�E�����I{���Zv_��m�T��B'�\O��5ʺ�}I��us��->*��o�M�$�?����f� Yf	8���β��t�V���,���3�1�����70���|6E�n�&s��e��v�f]�UT�����sב\g{�(L�e�lx�-\�F��2
�ew�l�Y ��ywq���X�>�EE�I<���^���\l.焔c�n�����h�m�� H��� �y������&+ּ�1��^�6�էE�:�փ;G��z�$	�I�a��ރd�X"���N�x8��J����?{����+�S�Н=�)`yM�\KG*���]���.�_�Jz�02��|�����G��j�[P��%��`d���z�=�JD��qp���B�t{lx�S��� ���_�~�?F�5      �   ?   x�KO,�4�*O,I-�4���Pڄ+(k
&͸RsR�K�2�3K*9͡*,PD-���\1z\\\ �G      �      x�u[[�d'�����@���Zf�똈�����R��I	I���ɶ�o����'������6�3����OyJJ�˟��=�)���~��֗�ۂ����	k������gO����͓�N���˵'=y�f�7�� �}�)yR�� tr�zY�������g�U�M�kQ9�C�qϰ��M�k����ԧ~�V���65��f�I5r���k��Y�g��2e����mK����A靕���n>Ǐ�r�;��J�G-�#(}���ϝ箅{����Ө��jN_�b��3��&�חo(~��]�WvE4�o��
̤p��*E��7�A�¸�*��1;��82kɴ��Y��>�f���� Y=T�l�*TP��w �\�7l��]��P���03��
~�\X����Zj�	�2��{hU�7�K�*�VK���r����+?T�KS����\�#�E`��\AKl
�B�Я��U�R��q��+[��βθ:�%'��'D`��5���nK�+<ɵ��e5d
�01����]��01�r�,�V1�D��`�2c�(uTr��y��s!b"��$�=y���%®X�Y��.3����%G%@j���E� �1h�;e��?���rJ����L�)�3]Q��Fv��r�0&)��ʃM�_����G�O�������R�V�[�@���������h��8#cW֝��&�'�via�隃E`z����_���Τ톳�^�}�XI�s�jzp5��wm�l��9����-�E`:��K�ʨhtc�L�,��擆��������7+��S��O��#�ʁ���m.?}:����̈y��t�ȗ�=X����	˩�&�}+;`a�G���Y���F���蠨�J��o+�������c��pFQQd��e�y��I��� ��ʓ�>���IV�m�(aPf�d����U�^��c�h��~X�G��̬�^��jѺ)����1������H��ٔ8��%�M-%3���5S�z��I6�^#f�&�,�\��b����36��s-<(����d��0@K���CUU���#�y�_3T���^���g�R�c*��K�ɹH�ǥuG��۬L���ӥ�1 �ܘ)��9�SW͊��RU�TM���s`;�tR���J�HJn�@]�+G�gwh�՘�KD]������H�Q0�� ���H��kĢW��*��)���Gf�g���aAڄL�5����j�_�t�֌4^�45`�i�"��7.�U͛7%B[�Fދ+"qp��g}�ܘ/�%0=)=�=�G����ٓ9]f����Ю�J`�\��<�J4мx*��)�k7G����S�����.����L6���=t^*R�rI�Q#��9Ig��(��i�u͒t6����;��&s��9���r���{�ؽ���r$�c@[()�p�[|B�Paө�����4u>�˄"@���Mצ�A+���<'%e�
]!~��vVoQ*���]�a>ؕs��irv!�mR�;�M��Y��<�����U$jX�`��M�|�P��D��^*49��)gZbg@�Ţz��Y�,��U'+3/3S}v?Cm�_�b�k�N�)p�L�T�X��.�̶�f���gr۩�j��0%��s�y�Ǆ����~kc[�PG7(�N��	(�Wߣ(��-�XFqt���*]I�c*J�0m^�7&k���]���7ˇ+�.��Aqt	��h��uk��J�]�(�,t�^�&����3�!��&����Y{Ģ�0Q>u��#�ɾ[P����	����Ѥ��S��6M���7�Oq�X��Z������8�	���Q8r�h��/��)ͣ�K,𾴘�z+�]���LG���7�x�2<t)4���/#L-d����孖�/4�2���t��^���Sk��&�������	�Fq��a/�'�6	��jӓ�V�EmG�R��<����G���!��Z�S-(��N�2�e%�*q�2�����G{��Jqt�Lvsw�TP� ��ϥɮ�%�F�|�x�>.� ��[6d��M�Mt��6��y�B�=(�-�qt��Y� _q���\9T5�{��gu�ܣDQ(B��i722kmӥC�n4���9�X���pR?j]��&�>�U]#���F�5��d�hB"�~\=�zZM="ы�z�݃=)�M���0�4'�H�R.=)�: �����%٤�7@�}$�.��'D?k�B�c�c.�M"���2.����ڦ.��9ϣ����'�cK{m�n��ź��E19%_�hPx�����=��x�
�=l�vt�9glgEF�$q�{�|�LW3�٣D�o�s��(v4�G�H�}w�И��].N�\�<�U��hԺ/Y��̗J2��U� �V�c���Y�],Rx�Q"Vg�%0E�c]t0=j�:Nu��**/��G�p};�U-d��=�u���y`�P��"]�|��M�J
� �{4���8ctt`�F�G��T$8�v:��&k�.�~,�� �Ψd1;�k{f]D6��s�����/�@�����U�=�����qt�$��n
���!���a�wv`��%u<q_��s���8x���A�y_�8x�8w��U>XG���z9�/�rgwJ�Y��t��N��)�,�'�˼��w� =Ҷ(�v��/�ወBq���	�+t6��^7����!��Ҹ�P,OQ#x�P�M�w���u��Y�pp�(c�#B�P{�]�`�
���$�ƳI�fmȭ#r�x�������<�A'��7���,�Q���q���K�V;�:���g��T��=���<Q�Eqt�t�u;�e����3qI�GV�}T��S6���-��q^-����t8J�-_�krm���@��0���؏ɏF��~��[ce��ڛW�>�=�.��	`�PD��e?Ȳ��	-n���{n���30�'N��i���5�l��&E��yy�`zXAt�8�Fs���1�8Z�Ƿ���Y�Bk8�R�̆L����kx[�c�#��9�U[B��g0GU]� �Q��v:�S���#y���&k� �y<FD����(|K}.��0�>��Ս?:(F�e��P�����(D����S�Sn��SgZL~�X�3yЍH�|Rd�8��ɽu��"���P��를O���Q�G<����%�-	�J8�zj�\��+lsIMgZ�\,L���&~È�;5ŭ�q&�K��O���Ϊi�.Y�����3 ��d7L����V#���a���3����f�H��Ź�1���8G���oU+�HLR!���[��|�7��`R��^/i9���E�h���;��=2ND��v^����w.p?�tF��㜒��mP��u�ꮵ=�#�� �"2f�'=�]z�&��h>�sc��t���yM�lz;_D�X��o��*c��z��9�萜��U�l�hXDGr^]�ʟM��C������J�Qm���A28*L�.��)�n�m�q�����~~�x'�?�cv��W&�	z���e�_{p�\wP]=�]��Ymb �> ��/���	H�8��[������I�F:��:�r�5���K�h]T�����Ǯ���b#����V)�����D_E�ih�.����C'�Xl� ��z��/�a���;��F�=�\��&LM����{uM">e|����3�B->}֋�Lqt���j/]�,?�U�w;�7�d-�'q~��=���y�G��ы���!=�f���kQ�y�0�ə�P���~���t6}�~ʖ��� ��w��ݙ�qaiẓ��w�<���6ҫ�i���Y?���g��������8Ƌ�wRЃT��7z� "��U�B�]��YF�^�E[r��8|>y�Lj �Y���cm�q�د�/���'Bq�vvy�tk���I��c�2!w��xr���:�m��$�K$��O]���]��;��I_�|;ד.�h�C�&8�+��z9��J��Fq�{-r:|6��e~��D�yƸ\����?_G�ϱ �  �陴	[��3��S��83`]>.�'�z����Fó�Dh�{�2��bU>6q�G�B^jhO��|�'�6 ��Ȟv��J��1"�	�{�\06wDN����h�!�M�32�D���`�tm�d��)�g�\b��!�Y�5{��#�x���ΐ�,򚽍ϥ��HH����Io�����B4�C�O�|�I�7fT��Eۍ�ϻR��H��)���)��RB�*�Z���:�~�{�<�f|��߾�I�#��a��w �����}2�G+k�wW�=#]n���	4B˜٨"{Z��7�& ���-��w�h��������gN�X����y��=���_��1Hj�I���i�ڨW%5��ǜ"����,�'���h�v�V�w���������8�\�-����J՞0ې'y]��-#����niϼͬ"{��2IUBV3��K�����Y(��ȁ�/���4����2�A�Wiµ�����1iw�Ú���?���~~��o�"     