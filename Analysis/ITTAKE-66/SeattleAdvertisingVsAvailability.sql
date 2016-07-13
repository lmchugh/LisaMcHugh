---ITTAKE-66  This query brings back all enabled Seattle Listings for 2015 along with their days available and days booked.
SELECT 
		l.RentalNumber,
		l.ListingId,
		l.ListingStatus,
		l.ListingURL,
		l.Address1,
		l.Address2,
		l.City,
		l.State,
		l.PostalCode,
		l.FirstLiveDate,
		q.NightsRentedIn2015,
		DaysAvailableIn2015
FROM   
		dw.dbo.vw_listing l
--enabled in 2015?
JOIN 
		(
		SELECT 
			listingid, 
			MAX(rowenddate)LastLiveDateIn2015 
		FROM dw..vw_listingattributes la
		WHERE 
			la.listingstatus = 'Enabled'
			AND (la.rowstartdate BETWEEN '2015-01-01' AND '2015-12-31' 
			OR la.rowenddate BETWEEN '2015-01-01' AND '2015-12-31')
		GROUP BY 
			listingid
		) la  ON l.listingid = la.ListingId
--Get a sum of the booked nights per listing
LEFT JOIN 
		(
		SELECT    
			listingid,
			SUM(DATEDIFF(DAY, checkindate, checkoutdate)) AS NightsRentedIn2015
		FROM      dw..vw_quotefact qf
		JOIN dw..vw_quoteItem qi ON qf.quoteItemId = qi.QuoteItemId
		WHERE     
			1 = 1
			AND CheckInDate BETWEEN '2015-01-01' AND '2015-12-31'
			AND bookingdate IS NOT NULL
			AND ReservationCancelledDate IS NULL
			AND qi.quoteItemType = 'Rental_Amount'
		GROUP BY  
			listingid
		) q ON q.listingid = l.ListingId
--Get a sum of the available nights per listing
LEFT JOIN
		(
		SELECT 
			ListingId,
			SUM(LiveListingDays) AS DaysAvailableIn2015
		FROM 
			[DW].[dbo].[VW_ListingMonthlyFact]
		WHERE
			dateid BETWEEN '2015-01-01' AND '2015-12-31'
		GROUP BY 
			listingid
		) lmf ON lmf.listingid = l.listingid
WHERE	
		1 = 1
		AND l.city = 'Seattle'
		OR l.PostalCode IN ( '98168', '98116', '98136', '98126', '98106',
                     '98108', '98134', '', '98118', '98108', '98134',
                     '98178', '98144', '98104', '98112', '98104','98122', 
                     '98144', '98101', '98102', '', '98115', '98105', 
                     '98103', '98102', '98195', '98115', '', '98177', 
                     '98133', '98125', '98103', '98115', '', '98177', 
                     '98117', '98107', '98103', '98115', '98105', '', 
                     '98121', '98101', '98154', '98104', '98199', 
                     '98119', '98109' )
