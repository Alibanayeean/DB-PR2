PGDMP  *                    {         
   smart-city    15.5    16.1 i    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    49401 
   smart-city    DATABASE     �   CREATE DATABASE "smart-city" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE "smart-city";
                postgres    false            �            1255    49402 ?   f1(integer, timestamp with time zone, timestamp with time zone)    FUNCTION     l  CREATE FUNCTION public.f1(ssn integer, st timestamp with time zone, en timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
END; $$;
 `   DROP FUNCTION public.f1(ssn integer, st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            �            1255    49682 0   f10(character varying, timestamp with time zone)    FUNCTION     �  CREATE FUNCTION public.f10(person_id character varying, month timestamp with time zone) RETURNS TABLE(cost_sum integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT SUM(cost) as cost_sum
		FROM (
			SELECT cost
				FROM parking_receipt AS pr
					JOIN citizen ON pr.driver=citizen.ssn
				WHERE month <= extract(month from enter_time)
					AND month >= extract(month from exit_time)
					AND ssn = person_id
			UNION
			SELECT cost
				FROM trip_receipt
					NATURAL JOIN citizen
				WHERE month <= extract(month from start_time) 
					AND month >= extract(month from end_time)
					AND ssn = person_id
			UNION
			SELECT supervisor, cost
				FROM urban_service_receipt AS usr
					JOIN home ON usr.owner=home.hid
					JOIN citizen ON home.owner=citizen.ssn
				WHERE month <= extract(month from date) 
					AND month >= extract(month from date)
					AND ssn = person_id
		) as costs_for_one_person_in_a_month;
END; $$;
 W   DROP FUNCTION public.f10(person_id character varying, month timestamp with time zone);
       public          postgres    false            �            1255    49679 T   f10_additonal(character varying, timestamp with time zone, timestamp with time zone)    FUNCTION     3  CREATE FUNCTION public.f10_additonal(person_id character varying, st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(cost_sum integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT SUM(cost) as cost_sum
		FROM (
			SELECT cost
				FROM parking_receipt AS pr
					JOIN citizen ON pr.driver=citizen.ssn
				WHERE st <= enter_time
					AND en >= exit_time
					AND ssn = person_id
			UNION
			SELECT cost
				FROM trip_receipt
					NATURAL JOIN citizen
				WHERE st <= start_time
					AND en >= end_time
					AND ssn = person_id
			UNION
			SELECT supervisor, cost
				FROM urban_service_receipt AS usr
					JOIN home ON usr.owner=home.hid
					JOIN citizen ON home.owner=citizen.ssn
				WHERE st <= date
					AND en >= date
					AND ssn = person_id
		) as costs_for_one_person;
END; $$;
 {   DROP FUNCTION public.f10_additonal(person_id character varying, st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            �            1255    49403 6   f2(timestamp with time zone, timestamp with time zone)    FUNCTION       CREATE FUNCTION public.f2(st timestamp with time zone, en timestamp with time zone) RETURNS TABLE(supervisor character varying, cost_sum integer)
    LANGUAGE plpgsql
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
END; $$;
 S   DROP FUNCTION public.f2(st timestamp with time zone, en timestamp with time zone);
       public          postgres    false            �            1259    49404    adj_station    TABLE     �   CREATE TABLE public.adj_station (
    stid_firs integer NOT NULL,
    stid_sec integer NOT NULL,
    distance integer NOT NULL,
    duration integer NOT NULL
);
    DROP TABLE public.adj_station;
       public         heap    postgres    false            �            1259    49407    car    TABLE     �   CREATE TABLE public.car (
    cid integer NOT NULL,
    color character varying(32) NOT NULL,
    brand character varying(32) NOT NULL
);
    DROP TABLE public.car;
       public         heap    postgres    false            �            1259    49410    citizen    TABLE     �  CREATE TABLE public.citizen (
    ssn character varying(10) NOT NULL,
    dob date NOT NULL,
    fname character varying(256) NOT NULL,
    lname character varying(256) NOT NULL,
    gender character varying(10) NOT NULL,
    supervisor character varying(10) NOT NULL,
    CONSTRAINT gender CHECK (((gender)::text = ANY (ARRAY[('male'::character varying)::text, ('female'::character varying)::text])))
);
    DROP TABLE public.citizen;
       public         heap    postgres    false            �            1259    49416    citizen_acc    TABLE     �   CREATE TABLE public.citizen_acc (
    ssn character varying(10) NOT NULL,
    acc_no character varying(16) NOT NULL,
    balance integer DEFAULT 0 NOT NULL
);
    DROP TABLE public.citizen_acc;
       public         heap    postgres    false            �            1259    49420    history    TABLE     I   CREATE TABLE public.history (
    code character varying(32) NOT NULL
);
    DROP TABLE public.history;
       public         heap    postgres    false            �            1259    49423    home    TABLE     �   CREATE TABLE public.home (
    address character varying(256) NOT NULL,
    hid integer NOT NULL,
    owner character varying(10) NOT NULL,
    loc point NOT NULL
);
    DROP TABLE public.home;
       public         heap    postgres    false            �            1259    49426    network    TABLE     �   CREATE TABLE public.network (
    nid integer NOT NULL,
    cost_per_km integer NOT NULL,
    path integer NOT NULL,
    trid integer NOT NULL
);
    DROP TABLE public.network;
       public         heap    postgres    false            �            1259    49429    parking    TABLE     Z  CREATE TABLE public.parking (
    cost integer NOT NULL,
    name character varying(256) NOT NULL,
    pid integer NOT NULL,
    capacity integer NOT NULL,
    start_time time with time zone DEFAULT '08:00:00-05'::time with time zone NOT NULL,
    end_time time with time zone DEFAULT '23:59:00-05'::time with time zone NOT NULL,
    loc path
);
    DROP TABLE public.parking;
       public         heap    postgres    false            �            1259    49434    parking_receipt    TABLE     H  CREATE TABLE public.parking_receipt (
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
       public         heap    postgres    false            �            1259    49437    path    TABLE     a   CREATE TABLE public.path (
    pid integer NOT NULL,
    name character varying(256) NOT NULL
);
    DROP TABLE public.path;
       public         heap    postgres    false            �            1259    49440    personal_car    TABLE     i   CREATE TABLE public.personal_car (
    cid integer NOT NULL,
    owner character varying(10) NOT NULL
);
     DROP TABLE public.personal_car;
       public         heap    postgres    false            �            1259    49443 
   public_car    TABLE     �   CREATE TABLE public.public_car (
    cid integer NOT NULL,
    trid integer NOT NULL,
    driver character varying(10) NOT NULL
);
    DROP TABLE public.public_car;
       public         heap    postgres    false            �            1259    49446    public_car_driver    TABLE     v   CREATE TABLE public.public_car_driver (
    public_car integer NOT NULL,
    driver character varying(10) NOT NULL
);
 %   DROP TABLE public.public_car_driver;
       public         heap    postgres    false            �            1259    49449    station    TABLE     s   CREATE TABLE public.station (
    name character varying(256) NOT NULL,
    sid integer NOT NULL,
    loc point
);
    DROP TABLE public.station;
       public         heap    postgres    false            �            1259    49452    station_path    TABLE     Z   CREATE TABLE public.station_path (
    stid integer NOT NULL,
    pid integer NOT NULL
);
     DROP TABLE public.station_path;
       public         heap    postgres    false            �            1259    49455 	   trans_car    TABLE     h   CREATE TABLE public.trans_car (
    transportation integer NOT NULL,
    public_car integer NOT NULL
);
    DROP TABLE public.trans_car;
       public         heap    postgres    false            �            1259    49458    transportation    TABLE     k   CREATE TABLE public.transportation (
    trid integer NOT NULL,
    type character varying(10) NOT NULL
);
 "   DROP TABLE public.transportation;
       public         heap    postgres    false            �            1259    49461    trip    TABLE     �   CREATE TABLE public.trip (
    trip_code character varying(32) NOT NULL,
    driver character varying(10) NOT NULL,
    car integer NOT NULL,
    path integer NOT NULL
);
    DROP TABLE public.trip;
       public         heap    postgres    false            �            1259    49464    trip_receipt    TABLE     o  CREATE TABLE public.trip_receipt (
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
       public         heap    postgres    false            �            1259    49467    urban_service    TABLE     (  CREATE TABLE public.urban_service (
    type character varying(16) NOT NULL,
    usid integer NOT NULL,
    CONSTRAINT urban_service_type_check CHECK (((type)::text = ANY (ARRAY[('water'::character varying)::text, ('electricity'::character varying)::text, ('gas'::character varying)::text])))
);
 !   DROP TABLE public.urban_service;
       public         heap    postgres    false            �            1259    49471    urban_service_receipt    TABLE     "  CREATE TABLE public.urban_service_receipt (
    code character varying(32) NOT NULL,
    date timestamp with time zone NOT NULL,
    usage integer NOT NULL,
    owner integer NOT NULL,
    usid integer NOT NULL,
    history_code character varying(32) NOT NULL,
    cost integer NOT NULL
);
 )   DROP TABLE public.urban_service_receipt;
       public         heap    postgres    false            �            1259    49683    view_2    VIEW     1  CREATE VIEW public.view_2 AS
 SELECT stations.staion,
    count(stations.ssn) AS passengers
   FROM ( SELECT tr.start_station AS staion,
            tr.ssn
           FROM public.trip_receipt tr
          WHERE (abs(date_part('day'::text, (tr.start_time - CURRENT_TIMESTAMP))) <= (1)::double precision)
        UNION
         SELECT tr.end_station AS staion,
            tr.ssn
           FROM public.trip_receipt tr
          WHERE (abs(date_part('day'::text, (tr.end_time - CURRENT_TIMESTAMP))) <= (1)::double precision)) stations
  GROUP BY stations.staion;
    DROP VIEW public.view_2;
       public          postgres    false    232    232    232    232    232            �          0    49404    adj_station 
   TABLE DATA           N   COPY public.adj_station (stid_firs, stid_sec, distance, duration) FROM stdin;
    public          postgres    false    214   8�       �          0    49407    car 
   TABLE DATA           0   COPY public.car (cid, color, brand) FROM stdin;
    public          postgres    false    215   U�       �          0    49410    citizen 
   TABLE DATA           M   COPY public.citizen (ssn, dob, fname, lname, gender, supervisor) FROM stdin;
    public          postgres    false    216   r�       �          0    49416    citizen_acc 
   TABLE DATA           ;   COPY public.citizen_acc (ssn, acc_no, balance) FROM stdin;
    public          postgres    false    217   ��       �          0    49420    history 
   TABLE DATA           '   COPY public.history (code) FROM stdin;
    public          postgres    false    218   ��       �          0    49423    home 
   TABLE DATA           8   COPY public.home (address, hid, owner, loc) FROM stdin;
    public          postgres    false    219   ɔ       �          0    49426    network 
   TABLE DATA           ?   COPY public.network (nid, cost_per_km, path, trid) FROM stdin;
    public          postgres    false    220   �       �          0    49429    parking 
   TABLE DATA           W   COPY public.parking (cost, name, pid, capacity, start_time, end_time, loc) FROM stdin;
    public          postgres    false    221   �       �          0    49434    parking_receipt 
   TABLE DATA           l   COPY public.parking_receipt (prid, pid, car, driver, history_code, cost, exit_time, enter_time) FROM stdin;
    public          postgres    false    222    �       �          0    49437    path 
   TABLE DATA           )   COPY public.path (pid, name) FROM stdin;
    public          postgres    false    223   =�       �          0    49440    personal_car 
   TABLE DATA           2   COPY public.personal_car (cid, owner) FROM stdin;
    public          postgres    false    224   Z�       �          0    49443 
   public_car 
   TABLE DATA           7   COPY public.public_car (cid, trid, driver) FROM stdin;
    public          postgres    false    225   w�       �          0    49446    public_car_driver 
   TABLE DATA           ?   COPY public.public_car_driver (public_car, driver) FROM stdin;
    public          postgres    false    226   ��       �          0    49449    station 
   TABLE DATA           1   COPY public.station (name, sid, loc) FROM stdin;
    public          postgres    false    227   ��       �          0    49452    station_path 
   TABLE DATA           1   COPY public.station_path (stid, pid) FROM stdin;
    public          postgres    false    228   Ε       �          0    49455 	   trans_car 
   TABLE DATA           ?   COPY public.trans_car (transportation, public_car) FROM stdin;
    public          postgres    false    229   �       �          0    49458    transportation 
   TABLE DATA           4   COPY public.transportation (trid, type) FROM stdin;
    public          postgres    false    230   �       �          0    49461    trip 
   TABLE DATA           <   COPY public.trip (trip_code, driver, car, path) FROM stdin;
    public          postgres    false    231   %�       �          0    49464    trip_receipt 
   TABLE DATA           |   COPY public.trip_receipt (history_code, start_station, end_station, ssn, trip_code, cost, start_time, end_time) FROM stdin;
    public          postgres    false    232   B�       �          0    49467    urban_service 
   TABLE DATA           3   COPY public.urban_service (type, usid) FROM stdin;
    public          postgres    false    233   _�       �          0    49471    urban_service_receipt 
   TABLE DATA           c   COPY public.urban_service_receipt (code, date, usage, owner, usid, history_code, cost) FROM stdin;
    public          postgres    false    234   |�       �           2606    49475    adj_station adj_station_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.adj_station
    ADD CONSTRAINT adj_station_pkey PRIMARY KEY (stid_firs, stid_sec);
 F   ALTER TABLE ONLY public.adj_station DROP CONSTRAINT adj_station_pkey;
       public            postgres    false    214    214            �           2606    49477     public_car_driver car_owner_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.public_car_driver
    ADD CONSTRAINT car_owner_pkey PRIMARY KEY (public_car, driver);
 J   ALTER TABLE ONLY public.public_car_driver DROP CONSTRAINT car_owner_pkey;
       public            postgres    false    226    226            �           2606    49479    car car_pkey 
   CONSTRAINT     K   ALTER TABLE ONLY public.car
    ADD CONSTRAINT car_pkey PRIMARY KEY (cid);
 6   ALTER TABLE ONLY public.car DROP CONSTRAINT car_pkey;
       public            postgres    false    215            �           2606    49481    citizen_acc citizen_acc_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.citizen_acc
    ADD CONSTRAINT citizen_acc_pkey PRIMARY KEY (ssn, acc_no);
 F   ALTER TABLE ONLY public.citizen_acc DROP CONSTRAINT citizen_acc_pkey;
       public            postgres    false    217    217            �           2606    49483    citizen citizen_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.citizen
    ADD CONSTRAINT citizen_pkey PRIMARY KEY (ssn);
 >   ALTER TABLE ONLY public.citizen DROP CONSTRAINT citizen_pkey;
       public            postgres    false    216            �           2606    49485    history history_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_pkey PRIMARY KEY (code);
 >   ALTER TABLE ONLY public.history DROP CONSTRAINT history_pkey;
       public            postgres    false    218            �           2606    49487    home home_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY public.home
    ADD CONSTRAINT home_pkey PRIMARY KEY (hid);
 8   ALTER TABLE ONLY public.home DROP CONSTRAINT home_pkey;
       public            postgres    false    219            �           2606    49489    network network_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_pkey PRIMARY KEY (nid);
 >   ALTER TABLE ONLY public.network DROP CONSTRAINT network_pkey;
       public            postgres    false    220            �           2606    49491    parking parking_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.parking
    ADD CONSTRAINT parking_pkey PRIMARY KEY (pid);
 >   ALTER TABLE ONLY public.parking DROP CONSTRAINT parking_pkey;
       public            postgres    false    221            �           2606    49493 $   parking_receipt parking_receipt_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_pkey PRIMARY KEY (history_code);
 N   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_pkey;
       public            postgres    false    222            �           2606    49495    path path_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY public.path
    ADD CONSTRAINT path_pkey PRIMARY KEY (pid);
 8   ALTER TABLE ONLY public.path DROP CONSTRAINT path_pkey;
       public            postgres    false    223            �           2606    49497    personal_car personal_car_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.personal_car
    ADD CONSTRAINT personal_car_pkey PRIMARY KEY (cid);
 H   ALTER TABLE ONLY public.personal_car DROP CONSTRAINT personal_car_pkey;
       public            postgres    false    224            �           2606    49499    public_car public_car_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_pkey PRIMARY KEY (cid);
 D   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_pkey;
       public            postgres    false    225            �           2606    49501    station_path station_path_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.station_path
    ADD CONSTRAINT station_path_pkey PRIMARY KEY (stid, pid);
 H   ALTER TABLE ONLY public.station_path DROP CONSTRAINT station_path_pkey;
       public            postgres    false    228    228            �           2606    49503    station station_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.station
    ADD CONSTRAINT station_pkey PRIMARY KEY (sid);
 >   ALTER TABLE ONLY public.station DROP CONSTRAINT station_pkey;
       public            postgres    false    227            �           2606    49505    trans_car trans_car_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.trans_car
    ADD CONSTRAINT trans_car_pkey PRIMARY KEY (transportation, public_car);
 B   ALTER TABLE ONLY public.trans_car DROP CONSTRAINT trans_car_pkey;
       public            postgres    false    229    229            �           2606    49507 "   transportation transportation_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.transportation
    ADD CONSTRAINT transportation_pkey PRIMARY KEY (trid);
 L   ALTER TABLE ONLY public.transportation DROP CONSTRAINT transportation_pkey;
       public            postgres    false    230            �           2606    49508 (   transportation transportation_type_check    CHECK CONSTRAINT     �   ALTER TABLE public.transportation
    ADD CONSTRAINT transportation_type_check CHECK (((type)::text = ANY (ARRAY[('taxi'::character varying)::text, ('bus'::character varying)::text, ('metro'::character varying)::text]))) NOT VALID;
 M   ALTER TABLE public.transportation DROP CONSTRAINT transportation_type_check;
       public          postgres    false    230    230            �           2606    49510    trip trip_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_pkey PRIMARY KEY (trip_code);
 8   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_pkey;
       public            postgres    false    231            �           2606    49512    trip_receipt trip_receipt_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_pkey PRIMARY KEY (history_code);
 H   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_pkey;
       public            postgres    false    232            �           2606    49514     urban_service urban_service_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.urban_service
    ADD CONSTRAINT urban_service_pkey PRIMARY KEY (usid);
 J   ALTER TABLE ONLY public.urban_service DROP CONSTRAINT urban_service_pkey;
       public            postgres    false    233            �           2606    49516 0   urban_service_receipt urban_service_receipt_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.urban_service_receipt
    ADD CONSTRAINT urban_service_receipt_pkey PRIMARY KEY (history_code);
 Z   ALTER TABLE ONLY public.urban_service_receipt DROP CONSTRAINT urban_service_receipt_pkey;
       public            postgres    false    234            �           2606    49517 &   adj_station adj_station_stid_firs_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.adj_station
    ADD CONSTRAINT adj_station_stid_firs_fkey FOREIGN KEY (stid_firs) REFERENCES public.station(sid);
 P   ALTER TABLE ONLY public.adj_station DROP CONSTRAINT adj_station_stid_firs_fkey;
       public          postgres    false    3293    214    227            �           2606    49522 %   adj_station adj_station_stid_sec_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.adj_station
    ADD CONSTRAINT adj_station_stid_sec_fkey FOREIGN KEY (stid_sec) REFERENCES public.station(sid);
 O   ALTER TABLE ONLY public.adj_station DROP CONSTRAINT adj_station_stid_sec_fkey;
       public          postgres    false    214    3293    227            �           2606    49527 &   public_car_driver car_owner_owner_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car_driver
    ADD CONSTRAINT car_owner_owner_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn);
 P   ALTER TABLE ONLY public.public_car_driver DROP CONSTRAINT car_owner_owner_fkey;
       public          postgres    false    226    3271    216            �           2606    49532     citizen_acc citizen_acc_ssn_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.citizen_acc
    ADD CONSTRAINT citizen_acc_ssn_fkey FOREIGN KEY (ssn) REFERENCES public.citizen(ssn);
 J   ALTER TABLE ONLY public.citizen_acc DROP CONSTRAINT citizen_acc_ssn_fkey;
       public          postgres    false    217    3271    216            �           2606    49537    citizen citizen_supervisor_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.citizen
    ADD CONSTRAINT citizen_supervisor_fkey FOREIGN KEY (supervisor) REFERENCES public.citizen(ssn) NOT VALID;
 I   ALTER TABLE ONLY public.citizen DROP CONSTRAINT citizen_supervisor_fkey;
       public          postgres    false    216    3271    216            �           2606    49542    home homes_owner_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.home
    ADD CONSTRAINT homes_owner_fkey FOREIGN KEY (owner) REFERENCES public.citizen(ssn) NOT VALID;
 ?   ALTER TABLE ONLY public.home DROP CONSTRAINT homes_owner_fkey;
       public          postgres    false    219    216    3271            �           2606    49547    network network_trid_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_trid_fkey FOREIGN KEY (trid) REFERENCES public.path(pid) NOT VALID;
 C   ALTER TABLE ONLY public.network DROP CONSTRAINT network_trid_fkey;
       public          postgres    false    223    3285    220            �           2606    49552    network network_trid_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_trid_fkey1 FOREIGN KEY (trid) REFERENCES public.transportation(trid) NOT VALID;
 D   ALTER TABLE ONLY public.network DROP CONSTRAINT network_trid_fkey1;
       public          postgres    false    220    3299    230            �           2606    49557 (   parking_receipt parking_receipt_car_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_car_fkey FOREIGN KEY (car) REFERENCES public.car(cid) NOT VALID;
 R   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_car_fkey;
       public          postgres    false    3269    215    222            �           2606    49562 +   parking_receipt parking_receipt_driver_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_driver_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn) NOT VALID;
 U   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_driver_fkey;
       public          postgres    false    3271    222    216            �           2606    49567 1   parking_receipt parking_receipt_history_code_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_history_code_fkey FOREIGN KEY (history_code) REFERENCES public.history(code) NOT VALID;
 [   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_history_code_fkey;
       public          postgres    false    222    3275    218            �           2606    49572 (   parking_receipt parking_receipt_pid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_receipt
    ADD CONSTRAINT parking_receipt_pid_fkey FOREIGN KEY (pid) REFERENCES public.parking(pid);
 R   ALTER TABLE ONLY public.parking_receipt DROP CONSTRAINT parking_receipt_pid_fkey;
       public          postgres    false    3281    221    222            �           2606    49577 "   personal_car personal_car_cid_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.personal_car
    ADD CONSTRAINT personal_car_cid_fkey FOREIGN KEY (cid) REFERENCES public.car(cid);
 L   ALTER TABLE ONLY public.personal_car DROP CONSTRAINT personal_car_cid_fkey;
       public          postgres    false    3269    224    215            �           2606    49582 $   personal_car personal_car_owner_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personal_car
    ADD CONSTRAINT personal_car_owner_fkey FOREIGN KEY (owner) REFERENCES public.citizen(ssn) NOT VALID;
 N   ALTER TABLE ONLY public.personal_car DROP CONSTRAINT personal_car_owner_fkey;
       public          postgres    false    3271    224    216            �           2606    49587    public_car public_car_cid_fkey    FK CONSTRAINT     x   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_cid_fkey FOREIGN KEY (cid) REFERENCES public.car(cid);
 H   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_cid_fkey;
       public          postgres    false    215    3269    225            �           2606    49592 !   public_car public_car_driver_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_driver_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn);
 K   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_driver_fkey;
       public          postgres    false    3271    225    216            �           2606    49597 3   public_car_driver public_car_driver_public_car_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car_driver
    ADD CONSTRAINT public_car_driver_public_car_fkey FOREIGN KEY (public_car) REFERENCES public.public_car(cid) NOT VALID;
 ]   ALTER TABLE ONLY public.public_car_driver DROP CONSTRAINT public_car_driver_public_car_fkey;
       public          postgres    false    225    226    3289            �           2606    49602    public_car public_car_trid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.public_car
    ADD CONSTRAINT public_car_trid_fkey FOREIGN KEY (trid) REFERENCES public.transportation(trid);
 I   ALTER TABLE ONLY public.public_car DROP CONSTRAINT public_car_trid_fkey;
       public          postgres    false    230    225    3299            �           2606    49607 "   station_path station_path_pid_fkey    FK CONSTRAINT     }   ALTER TABLE ONLY public.station_path
    ADD CONSTRAINT station_path_pid_fkey FOREIGN KEY (pid) REFERENCES public.path(pid);
 L   ALTER TABLE ONLY public.station_path DROP CONSTRAINT station_path_pid_fkey;
       public          postgres    false    3285    223    228            �           2606    49612 #   station_path station_path_stid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.station_path
    ADD CONSTRAINT station_path_stid_fkey FOREIGN KEY (stid) REFERENCES public.station(sid);
 M   ALTER TABLE ONLY public.station_path DROP CONSTRAINT station_path_stid_fkey;
       public          postgres    false    227    228    3293                        2606    49617 #   trans_car trans_car_public_car_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trans_car
    ADD CONSTRAINT trans_car_public_car_fkey FOREIGN KEY (public_car) REFERENCES public.public_car(cid);
 M   ALTER TABLE ONLY public.trans_car DROP CONSTRAINT trans_car_public_car_fkey;
       public          postgres    false    225    3289    229                       2606    49622 '   trans_car trans_car_transportation_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trans_car
    ADD CONSTRAINT trans_car_transportation_fkey FOREIGN KEY (transportation) REFERENCES public.transportation(trid);
 Q   ALTER TABLE ONLY public.trans_car DROP CONSTRAINT trans_car_transportation_fkey;
       public          postgres    false    229    3299    230                       2606    49627    trip trip_car_fkey    FK CONSTRAINT     l   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_car_fkey FOREIGN KEY (car) REFERENCES public.car(cid);
 <   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_car_fkey;
       public          postgres    false    215    231    3269                       2606    49632    trip trip_driver_fkey    FK CONSTRAINT     v   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_driver_fkey FOREIGN KEY (driver) REFERENCES public.citizen(ssn);
 ?   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_driver_fkey;
       public          postgres    false    3271    231    216                       2606    49637    trip trip_path_fkey    FK CONSTRAINT     o   ALTER TABLE ONLY public.trip
    ADD CONSTRAINT trip_path_fkey FOREIGN KEY (path) REFERENCES public.path(pid);
 =   ALTER TABLE ONLY public.trip DROP CONSTRAINT trip_path_fkey;
       public          postgres    false    3285    231    223                       2606    49642 *   trip_receipt trip_receipt_end_station_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_end_station_fkey FOREIGN KEY (end_station) REFERENCES public.station(sid) NOT VALID;
 T   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_end_station_fkey;
       public          postgres    false    232    3293    227                       2606    49647 +   trip_receipt trip_receipt_history_code_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_history_code_fkey FOREIGN KEY (history_code) REFERENCES public.history(code) NOT VALID;
 U   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_history_code_fkey;
       public          postgres    false    232    3275    218                       2606    49652 "   trip_receipt trip_receipt_ssn_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_ssn_fkey FOREIGN KEY (ssn) REFERENCES public.citizen(ssn) NOT VALID;
 L   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_ssn_fkey;
       public          postgres    false    232    3271    216                       2606    49657 ,   trip_receipt trip_receipt_start_station_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_start_station_fkey FOREIGN KEY (start_station) REFERENCES public.station(sid) NOT VALID;
 V   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_start_station_fkey;
       public          postgres    false    3293    232    227            	           2606    49662 (   trip_receipt trip_receipt_trip_code_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trip_receipt
    ADD CONSTRAINT trip_receipt_trip_code_fkey FOREIGN KEY (trip_code) REFERENCES public.trip(trip_code) NOT VALID;
 R   ALTER TABLE ONLY public.trip_receipt DROP CONSTRAINT trip_receipt_trip_code_fkey;
       public          postgres    false    232    231    3301            
           2606    49667 6   urban_service_receipt urban_service_receipt_owner_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urban_service_receipt
    ADD CONSTRAINT urban_service_receipt_owner_fkey FOREIGN KEY (owner) REFERENCES public.home(hid);
 `   ALTER TABLE ONLY public.urban_service_receipt DROP CONSTRAINT urban_service_receipt_owner_fkey;
       public          postgres    false    3277    234    219                       2606    49672 5   urban_service_receipt urban_service_receipt_usid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urban_service_receipt
    ADD CONSTRAINT urban_service_receipt_usid_fkey FOREIGN KEY (usid) REFERENCES public.urban_service(usid) NOT VALID;
 _   ALTER TABLE ONLY public.urban_service_receipt DROP CONSTRAINT urban_service_receipt_usid_fkey;
       public          postgres    false    234    233    3305            �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �     