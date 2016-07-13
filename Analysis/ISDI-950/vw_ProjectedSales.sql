USE [BI]
GO

/****** Object:  View [dbo].[VW_ProjectedSales]    Script Date: 06/27/2016 15:14:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/********************************************************************************************
Author		: Lisa McHugh
Create Date	: 06/17/2016
Description	: This script creates the data source for users of ProjectedSalesFact

Audit Info:
Change By:			Date		Description
Lisa McHugh			07/13/2016  Removed join to PMCandidate.  Pulling those columns from customer. 
								Changed name from vw_ProjectedSalesFact_Datasource to vw_ProjectedSales.
*******************************************************************************************/
---DROP VIEW [dbo].[VW_ProjectedSales]

CREATE VIEW [dbo].[VW_ProjectedSales]
AS 

SELECT

/*DW_Facts.dbo.ProjectedSalesFact*/
	ps.ProjectedSalesSourceId AS SourceID,
	pss.ProjectedSalesSourceTableName,
---InvoiceItemId, OfferSignupId, QuotePaymentId
	ps.ProjectedSalesSourceRefId AS ReferenceID,
	ps.TransactionDate,

----Measures     
	ps.SalesAmount * USD.ConversionRate AS SalesAmountUSD,
	ps.SalesAmount * GBP.ConversionRate AS SalesAmountGBP,
	ps.SalesAmount * EU.ConversionRate AS SalesAmountEU,
	ps.SalesAmount,
	ps.UnitsCount,

/*dw.dbo.vw_Invoice*/
	i.OrderCurCode,	
	i.TaxRate,
	i.invoiceid,
	i.InvoiceType,
	i.InvoiceSource,
	i.InvoiceUUID,
	i.InvoiceUUIDCredited,
	i.TaxChargeFlag,
	i.OrderNum,
	i.OrderDetailNum,
	i.OrderNum + '/' + Convert(varchar(20),i.OrderDetailNum) AS TransactionId,
	i.OrderType,
	i.SaleOrderKey,

/*dw.dbo.vw_Brand*/
---Brand
	ps.InvoiceBrandId AS BrandId,
	b.BrandName AS InvoiceBrandName,
	b.GeoGroup ,	
	b.RegionalOperatingUnit,
	b.LocalOperatingUnit,
	b.FinanceBusinessUnit,
	b.NetworkFlag,
	b.CartStartDate,	
	b.CartVersionNum,	
	-----Master Brand
	ps.MasterBrandId,
	mb.BrandName AS MasterBrandName,
	-----Historical Brand
	ps.InvoiceBrandAttributesId,
	
---Site
/*dw.dbo.vw_Site*/
	ps.SiteId,
	s.SiteName,
	
---Listing Details
/*dw.dbo.vw_Listing*/
	ps.ListingId,
	list.SleepNum,
	list.Latitude,
	list.Longitude,
	list.BedroomNum,
	list.BathroomNum,
	list.RentalNumber,
	list.FirstLiveDate AS ListingFirstLiveDate,

/*dw.dbo.vw_ListingAttributes*/
	la.ListingId AS ListingId_Hist,
	la.AutoRenewalFlag AS ListingAutoRenewalFlag,
	la.ListingTenure,
	la.PaymentAccountTypeName,
	la.LiveFlag AS LiveFlag_Hist,
	la.PaymentsEnabled,
	la.QuotableRatesEnabled,
	la.NewListing,
	la.OnlineBookingEnabledFlag,
	la.OnlinePaymentsEnabledFlag,
	la.OfflinePaymentsEnabledFlag,
	la.ListingSourceName, 
	
---Tier
/*dw.dbo.vw_Tier*/
	tie.TierCode AS TierOfListing,
	
		
---Campaign
/*dw.dbo.vw_Campaign*/
	camp.CampaignName,

---Customer
/*dw.dbo.VW_CustomerAttributes*/
	ca.SupplierSegmentName AS SupplierSegmentName_Hist,
	ca.HAThreeCustomerSegmentationScore,
	SUBSTRING(ca.HAThreeCustomerSegmentationScore, 1, 1) AS CustomerEngagementScore,
	SUBSTRING(ca.HAThreeCustomerSegmentationScore, 2, 1) AS CustomerRevenueScore,
	ca.SupplierSegmentName,
	
/*dw.dbo.vw_Customer*/	
	cust.customerid,
	cust.TotalAvailableProperties,
	cust.TotalLiveListings,
	cust.AccountManagerName,
	cust.OwningTeam,
	--Segment,
	--AccountName,
	--CampaignOnAccount,
	
/*dw.dbo.VW_PersonType*/	
	per.PersonTypeName,

	---Device
/*DW.dbo.VW_DeviceCategorySession*/
	dcs.DeviceCategory,

---Invoice Category
/*dw.dbo.vw_InvoiceCategory*/

	ic.InvoiceCategoryName AS SalesType,

---Payment Type
/*dw.dbo.vw_PaymentType*/
	pt.PaymentType,
	pt.PaymentTypeAbbrv,

---Product 
/*dw.dbo.vw_Product*/    
	ps.ProductClusterId,
	ps.ProductId,
	pc.ProductFamily,
	pc.ProductCategory,
	pc.ProductClusterName,
	pc.ProductClass,	
	pc.ProductSuite,
	pc.ProductCustomer,

---Subscription     
/*dw.dbo.vw_Subscription*/	
	sub.OriginalEndDate,
	sub.Renewal,
	sub.RenewalCount,
	sub.SubscriptionStatusName,
	sub.SubscriptionStartDate,
	sub.SubscriptionEndDate,
	sub.TrialFlag,
	sub.SubscriptionDurationInMonths,
	
---Source Application
/*dw.dbo.vw_Application */
	i.SourceAppId,
	ap.AppName,
	
---Website referral medium     
/*dw.dbo.vw_WebsiteReferralMediumSession*/
	ps.WebsiteReferralMediumSessionId,
	web.MarketingMedium,

---historical strategic destination
/*dw.dbo.vw_DestinationAttributesStrategic*/
---use dw..vw_DestinationAttributes instead
	da.DestinationName AS DestinationName_Hist,
	da.DestinationFullName AS DestinationFullName_Hist,
	da.DestinationStatusCode AS DestinationStatusCode_Hist,
	da.DestinationStatusName AS DestinationStatusName_Hist

FROM 
	DW.dbo.vw_ProjectedSalesFact ps
	JOIN dw.dbo.ProjectedSalesSource ( NOLOCK ) pss ON ps.ProjectedSalesSourceId = pss.projectedsalessourceid
	LEFT JOIN dw.dbo.vw_InvoiceItem ii ON ps.projectedsalessourcerefid = ii.invoiceitemid
				AND ps.projectedsalessourceid = 1
	LEFT JOIN dw.dbo.vw_Invoice i ON ii.InvoiceId = i.invoiceid
	JOIN dw.dbo.vw_Brand b  ON ps.InvoiceBrandId=b.BrandId
	JOIN dw.dbo.vw_Brand mb ON ps.MasterBrandId=mb.BrandId
    JOIN dw.dbo.vw_Site	s ON ps.SiteId = s.SiteId
    JOIN dw.dbo.vw_Channel c ON ps.ListingChannelId = c.ChannelId
    JOIN dw.dbo.vw_Campaign camp ON ps.CampaignId = camp.CampaignId
	JOIN DW.dbo.vw_CurrencyConversion USD ON ps.CurrencyConversionIdUSD = USD.CurrencyConversionId
	JOIN DW.dbo.vw_CurrencyConversion EU ON ps.CurrencyConversionIdEU = EU.CurrencyConversionId
	JOIN DW.dbo.vw_CurrencyConversion GBP ON ps.CurrencyConversionIdGBP = GBP.CurrencyConversionId
	JOIN dw.dbo.vw_ordertype ot ON ps.OrderTypeId = ot.OrderTypeId
	LEFT JOIN dw.dbo.vw_Listing list ON ps.ListingId = list.ListingId
	JOIN dw.dbo.vw_ListingAttributes la ON ps.ListingAttributesId = la.ListingAttributesId
	JOIN dw.dbo.vw_Customer cust ON ps.CustomerId = cust.customerid
	JOIN dw.dbo.VW_CustomerAttributes ca ON ps.CustomerAttributesId = ca.CustomerAttributesId
	JOIN DW.dbo.VW_DeviceCategorySession AS dcs ON ps.DeviceCategorySessionId = dcs.DeviceCategorySessionId
	JOIN dw.dbo.vw_InvoiceCategory ic ON ps.InvoiceCategoryId = ic.InvoiceCategoryId
	JOIN dw.dbo.vw_PaymentType pt ON ps.PaymentTypeId = pt.PaymentTypeId
	JOIN dw.dbo.VW_PersonType per ON ps.PersonTypeId = per.PersonTypeId
	JOIN dw.dbo.Application ap ( NOLOCK ) ON ps.SourceAppId = ap.AppId
    JOIN dw.dbo.vw_WebsiteReferralMediumSession web ON ps.WebsiteReferralMediumSessionId = web.WebsiteReferralMediumSessionId
    LEFT JOIN dw.dbo.vw_DestinationAttributes da ON ps.StrategicDestinationAttributesId = da.DestinationAttributesId
    JOIN dw.dbo.vw_Tier tie ON la.tierid = tie.tierid
    JOIN dw.dbo.vw_Subscription sub ON ps.SubscriptionId = sub.SubscriptionId
    JOIN dw.dbo.vw_ProductCluster pc ( NOLOCK ) ON pc.ProductClusterId = ps.ProductClusterId

GO
GRANT SELECT
    ON OBJECT::[dbo].[VW_ProjectedSalesFact_Datasource] TO [WVRGROUP\ReportingAnalyticsTeam]
    AS [dbo]
GO
GRANT SELECT 
    ON [dbo].[VW_ProjectedSalesFact_Datasource] TO [HAHOSTING\prd-tab-svc] 
    AS [dbo]
GO
GRANT SELECT 
    ON [dbo].[VW_ProjectedSalesFact_Datasource] TO [WVRGROUP\IS-Data Insights] 
    AS [dbo]

GO 

