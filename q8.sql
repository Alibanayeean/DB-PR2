select count(*) as cars_with_specify_brand_and_color
	from (
		select prid, pid, car, brand, color, enter_time, exit_time
		from parking_receipt as pr
		natural join parking
		join car on car.cid = pr.car
		
		where enter_time <= st
		  and exit_time >= et
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
				where not cp.cid = cp_color.cid
				  and enter_time <= st
				  and exit_time >= et
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
			  where not cp.cid = cp_brand.cid
				  and enter_time <= st
				  and exit_time >= et
				  and pid = parking_id
		  )
		  