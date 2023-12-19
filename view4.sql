create view view_4 as 
	select h.hid
		from (select home.hid, urban_service_receipt.cost
			from urban_service natural join urban_service_receipt
			join home on urban_service_receipt.owner = home.hid
			  
			 where urban_service.type = 'electricity' and
			  urban_service_receipt.date >= (CURRENT_TIMESTAMP - INTERVAL '1 month')
			  and urban_service_receipt.date <= CURRENT_TIMESTAMP
		) as h
		
		group by h.hid
		having sum(h.cost) > 10000 -- given number