select count(cid), date_trunc('month', start_time) AS txn_month
	from public_car
	natural join trip
	natural join trip_receipt
	
	where 5 in (select stid
	from public_car as pc
	natural join trip
	natural join trip_receipt
	natural join path
	join station_path on path.pid = station_path.pid
	where cid = input_ --change this
	and start_time >= st
	and end_time <= et
	)
	group by txn_month