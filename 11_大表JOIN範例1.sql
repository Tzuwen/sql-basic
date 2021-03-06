USE [AllPay_Payment]
GO
/****** Object:  StoredProcedure [dbo].[ausp_Admin_AllPay_Payment_ListItemDetail_S]    Script Date: 2017/7/12 下午 01:27:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
'程式代號：[ausp_Admin_AllPay_Payment_ListItemDetail_S]
'程式名稱：
'目　　的：公告列表查詢
 
'參數說明：
(
	@AllPayTradeID		BIGINT		--AllPay交易序號
)	
	
'依存　　：無
'傳回值　：無
'副作用　：無
'備　註　：
'範　例　：


	EXEC	[dbo].[ausp_Admin_AllPay_Payment_ListItemDetail_S]
			@AllPayTradeNo ='1504301027532568' 
			,@MID =1003902



'版本變更：
'　xx.  YYYY/MM/DD       VER         AUTHOR          COMMENTS
'  ===  ============    ====        ==========      ==========
'	1. 2012/06/25					Matt Yeh		Create
'	2. 2012/10/15					Matt Yeh		修改join Member_Basic的key為AllPay_Payment_TradeNo.MID
'	3. 2013/05/07					Matt Yeh		新增回傳IsGuarantee，地址改抓AllPay_Payment_QuickPayShipping
'	4. 2013/05/16					Shary Lin		新增收件者資料
'	5. 2013/05/17					Faye Hsieh		新增回傳PaymentTypeID,PaymentSubTypeID,PaymentStatus
'	6. 2013/05/21					Faye Hsieh		新增回傳PaymentNotes
'	7. 2013/06/04					Faye Hsieh		新增回傳BankCode,vAccount,PaymentNo
'	8. 2013/06/13					Shary Lin		新增回傳買家的MID,Email
'	9. 2013/07/22					Justice Wu		新增回傳ShipCompany.
'  10. 2013/09/16					Shary Lin		新增回傳ShippingEmail.
'  11. 2013/10/05					Justice Wu		新增回傳Remark,TradeType,ConsiderLastHour.
'  12. 2013/11/11					Shary Lin		新增回傳AllocateDate.
'  13. 2013/11/20					Faye Hsieh		新增回傳ShippingDate,Remark,ItemTrackingNo,OtherShipCompany,ShipCompanyCode,MerchantName.
'  14. 2013/11/29					Justice Wu		新增回傳 CVSExpireDate.
'  15. 2013/12/06					Faye Hsieh		付款人資訊改帶AllPay_Payment_QuickPayShipping的資訊
'  16. 2014/01/02					Justice Wu		新增回傳 QuickPayID.
'
'  17. 2014/02/24			        Shary Lin		修改TradeStatusName欄位:未付款訂單取消 =>訂單取消 
'  18. 2014/05/28					Cloud Chen		新增回傳ShoppingAMT,ActualTotalAMT
'  19. 2014/08/05					Cloud Chen		新增回傳WebSiteURL,ContectPhone,MerchantTradeNo
'  20. 2014/08/20					Brady Weng		新增回傳AllPay_Payment_TradeDetail.QuickCollectChargeFeeTypeID
'  21. 2014/11/12					Nokia Chiang    新增回傳 預計撥款日,交易待撥金額,快速收款,商品圖片
                                                    修改 PaymentNotes 改 Join AllPay_Payment_TradeType 
'  22. 2014/11/19					Nokia Chiang    新增回傳  AddAddressStatus
'  23. 2014/12/23                   John Lu         增加回傳分期期數及紅利折抵
'  24. 2015/01/14                   Lisa            調整預計撥款日(FundingDate)
                                                    網路ATM、ATM櫃員機、臨櫃繳款、超商代碼、儲值支付帳戶、歐付寶帳戶餘額、支付寶、財付通
													→2015/1/6~1/12 2015-1-14 15:00
													→2015/1/13後  消費者付款成功後隔天下午3點
'  25. 2015/03/12                   lisa            運費抓取欄位調整(AllPay_Payment_QuickPayShipping 新加欄位Basefee後可抓取正確計算後運費)
'  26. 2015/04/30                   lisa            調整SP資料出現兩筆問題(因為過去資料結構未紀錄計算後運費，2015/03/12才增加。
                                                    故一址付設多筆運費設定時 AllPay_Payment_QuickPayShippingCharge join 會有多筆資料)
'  27. 2015/04/30					Nokia Chiang    新增回傳 收件資訊--統一編號
'  28. 2015/05/14					Justice Wu		新增回傳 RefundAMT, RefundDate.
'  29. 2015/05/13					Nokia Chiang    新增回傳 BalanceAMT.
'  30. 2015/05/21					Justice Wu		FundingAMT 增加判斷支付寶退款、延遲撥款交易、平台手續費. 新增回傳 ChargeFee,PaymentTypeChargeFee,PlatformChargeFee. 
'  31. 2015/06/02					Nick Chen		修改信用卡預計撥款日期(FundingDate)來源資料
'  32. 2015/06/05					Nick Chen		信用卡改版之前信用卡相關交易官網預計撥款日皆不顯示
'  33. 2015/06/16					Vince Su	    新增回傳 訂單金額內含手續費欄位 IncludeChargeFeeByBarCode,IncludeChargeFeeByCode
'  34. 2015/07/09					Vince Su	    新增回傳ZipCode 
                                                    新增join TradeDetail_eACH 回傳付款BankCode.
'  35. 2015/08/10					Justice Wu		回傳新增判斷快速取號付款人之 Email,CellPhone.
'  36. 2015/09/23					Justice Wu		FundingDate 增加判斷全家超商手機條碼(APPBarcode Fami),為下下個月底撥款.
'  37. 2016/04/20                   YiJin   Wu      增加購物金折抵金額(RedeemAmt)
'  38. 2016/04/25                   Emily  Sun      增加回傳額外手續費(PlusFeeAmt)
'  39. 2016/04/27                   YiJin   Wu      交易待撥金額需扣掉購物金(RedeemAmt)，因為購物金是商家自行負擔的，不會撥給商家。
'  40. 2016/07/27                   YiJin   Wu      新增判斷AND A.AllPayTradeNo=H.AllPayTradeNo
'  41. 2016/08/11                   Jarvis Zheng	新增回傳BarcodeStoreName(綁定貼紙的廠商名稱)
'  42. 2016/09/30                   Justice Wu		略過轉拋ECPay(PayUse=2)之訂單.
'  43. 2016/10/20                   Andy Chao		修正
'                                                   1.沒有回傳正確的 AllocateDate
'                                                   2.FundingAMT 要增加 EventCashCostBy 判斷
'  44. 2016/10/28                   Spark Lin		新增回傳：EventCashCostBy (活動成本誰買單 0:廠商 1:allPay)
'  45. 2017/01/17                   Spark Lin		新增回傳：撥款日期(AlreadyAllocateDate)、金流手續費率、撥款日期條件說明(AllocateDateDescr)、付款人稱謂(PayerTitle)
															  商店名稱(PayerMerchantName)、會員等級(PayerLevelID)、商店統一編號(BuyerUnifiedBusinessNo)、信用卡後4碼(card4no)
'  46. 2017/02/07                   Knock Yang		修改付款人姓名與手機取得判斷
'  47. 2017/04/07                   Roson Jan       增加欄位AllPay_Payment_TradeDetail.MerchantTradeDate
'  48. 2017/04/27                   Angus Kao       增加判斷個人/商務特店條件
'  49. 2017/05/05                   Spark Lin		#237 增加回傳收件人公司名稱(RecipientCompanyName)
'  50. 2017/05/22                   Spark Lin		#264 增加回傳一址付付款頁付款人選擇的宅配業者(QuickPayShipCompany)
***************************************************************************************************************************************************************************/
ALTER PROCEDURE [dbo].[ausp_Admin_AllPay_Payment_ListItemDetail_S]


@AllPayTradeNo		VARCHAR(20),
@MID				BIGINT



AS
BEGIN
	DECLARE @MerchantName		NVARCHAR(100)
	DECLARE @WebSiteURL         NVARCHAR(100)
	DECLARE @ContactPhone		NVARCHAR(20)

	--取得MerchantName
	SELECT @MerchantName = ISNULL(WebSiteName, MerchantName),
		   @WebSiteURL = WebSiteURL,
		   @ContactPhone = ContactPhone
	  FROM [AllPay_PaymentCenter].[dbo].[Payment_MerchantData]
	 WHERE MID = @MID

	SELECT
		A.AllPayTradeID
		, A.AllPayTradeNo
		, A.TradeStatus
		,(CASE WHEN F.StatusCode ='v341'
				 THEN '訂單取消'
				 ELSE F.StatusName
			END) AS  TradeStatusName
		, A.TradeTotalAMT
		, A.CreateDate
		, B.MerchantTradeDate
		, B.MerchantID
		, D.MID
		, D.MemberType
		, (CASE
		   WHEN H.PayEmail IS NOT NULL THEN H.PayEmail
		   WHEN QB.Email IS NOT NULL THEN QB.Email
		   ELSE E.Email
		   END) AS Email
		, (CASE 
		   WHEN H.PayCname IS NOT NULL THEN H.PayCname
		   ELSE D.CName
		   END)AS CName					        --付款人姓名
		, H.PayPhone AS Phone					--付款人市話
		, (CASE
		   WHEN H.PayCellPhone IS NOT NULL THEN H.PayCellPhone
		   WHEN QB.CellPhone IS NOT NULL THEN QB.CellPhone
		   ELSE E.CellPhone 
		   END) AS CellPhone					--付款人手機
		--, CASE WHEN D.CName IS NULL THEN H.PayCName ELSE D.CName END AS CName				  --付款人姓名
		--, CASE WHEN E.Phone IS NULL THEN H.PayPhone ELSE E.Phone END AS Phone				  --付款人市話
		--, CASE WHEN E.CellPhone IS NULL THEN H.PayCellPhone ELSE E.CellPhone END AS CellPhone --付款人手機
		, E.Address AS [Address]		   --付款人地址
		, H.Cname AS ShippingCname		   --收件人姓名
		, H.Phone AS ShippingPhone		   --收件人市話
		, H.CellPhone AS ShippingCellPhone --收件人手機
		, H.ZipCode	as ShippingZipCode	   --收件人地址郵遞區號
		, H.ShippingAddress				   --收件人地址
		, H.Remark AS ShippingRemark	   --收件人地址
		, H.UnifiedBusinessNo AS ShipUnifiedBusinessNo  --收件人統一編號
		, H.RecipientCompanyName
		, B.Remark
		, B.TradeDesc
		, B.TradeType 
		, B.QuickPayID  
		, C.ItemNo
		, C.ItemName
		, C.Quantity
		, C.Price
		, C.SubTotalAMT
		, C.ItemURL
		, C.ItemStatus
		, G.StatusCode  AS  ItemStatusName		
		, C.ConsiderHour
		, B.IsGuarantee 
		, A.PaymentTypeID
		, A.PaymentSubTypeID
		, A.PaymentStatus
		, T.PaymentNotes
		, J.BankCode
		, J.vAccount
		, K.PaymentNo
		, K.[ExpireDate] AS CVSExpireDate 
		, L.CompanyName AS ShipCompany 
		, L2.CompanyName AS QuickPayShipCompany 
		, H.Email AS ShippingEmail 
		,
		--猶豫期為付款時間開始計算，減掉系統日期的話，表示剩餘日期.
		CASE WHEN ((A.PaymentDate < '2012-01-01') OR (A.PaymentDate IS NULL))
			THEN 0 		--0表示為未出貨
			ELSE (DATEDIFF(MINUTE, GETDATE(), DATEADD(hh, ISNULL(C.ConsiderHour, 0), A.PaymentDate)) * 60 )
		END AS ConsiderLastHour,
		ISNULL(B.AllocateDate, R.AllocateDate) AS AllocateDate	--撥款日
		,C.ShippingDate
		,C.Remark AS ShipmentRemark
		,C.ItemTrackingNo 
		,C.OtherShipCompany
		,C.ShipCompany AS ShipCompanyCode
		,@MerchantName AS MerchantName
		,A.ShoppingAMT
		,A.ActualTotalAMT
		,@ContactPhone AS ContactPhone
		,@WebSiteURL AS WebSiteURL
		,B.MerchantTradeNo
		,B.QuickCollectChargeFeeTypeID
		--預計撥款日
		,	CASE
			   WHEN A.PaymentDate IS NOT NULL  AND A.PaymentStatus = 1 THEN
				   (CASE
					    WHEN A.PaymentTypeID IN (10000, 10020, 10021, 10022, 10023, 10026, 10027) --信用卡(撥款日+20天)
						   THEN
								A.PaymentDate + 7
					   WHEN A.PaymentTypeID IN (10003, 10005, 10016, 10017) THEN 
						   (CASE 
                                WHEN CAST(A.PaymentDate AS DATE) >= CAST('2015-01-13' AS DATE)--(2015/1/13 後都改為隔日PM15:00撥款)
								THEN
								      RTRIM(CAST(DATEADD(D, 1, CAST(A.PaymentDate AS DATE)) AS CHAR)) + ' 15:00:00.000'  
							    
								WHEN CAST(A.PaymentDate AS DATE) >= CAST('2015-01-06' AS DATE)--(2015/1/6~1/12 後都改為2015/1/14 PM15:00撥款)
								THEN
								     '2015-01-14 15:00:00.000'
								
								WHEN CAST(A.PaymentDate AS DATE) >= CAST('2014-08-01' AS DATE)--超商收款、AliPay、TenPay(8/1後都改為付款後7天撥款)
							    THEN    
							        A.PaymentDate + 7
							    ELSE   				
						          (CASE
							         WHEN DATEPART (D, A.PaymentDate) BETWEEN 1 AND 10 THEN	--超商收款、AliPay、TenPay(1~10付款→當月26號撥,11~20付款→隔月6號撥,21~30付款→隔月16號撥)
							  	         CONVERT(VARCHAR(8), A.PaymentDate, 120) + '26'
							         WHEN DATEPART (D, A.PaymentDate) BETWEEN 11 AND 20 THEN
								         CONVERT(VARCHAR(8), DATEADD(M, 1, A.PaymentDate), 120)+ '06'
							         ELSE
								         CONVERT(VARCHAR(8), DATEADD(M, 1, A.PaymentDate), 120) + '16'
						            END)
						     END) 
					    WHEN A.PaymentTypeID IN (10004) THEN 
						   (CASE                                
								WHEN CAST(A.PaymentDate AS DATE) >= CAST('2014-08-01' AS DATE)--超商收款、AliPay、TenPay(8/1後都改為付款後7天撥款)
							    THEN    
							        A.PaymentDate + 7
							    ELSE   				
						          (CASE
							         WHEN DATEPART (D, A.PaymentDate) BETWEEN 1 AND 10 THEN	--超商收款、AliPay、TenPay(1~10付款→當月26號撥,11~20付款→隔月6號撥,21~30付款→隔月16號撥)
							  	         CONVERT(VARCHAR(8), A.PaymentDate, 120) + '26'
							         WHEN DATEPART (D, A.PaymentDate) BETWEEN 11 AND 20 THEN
								         CONVERT(VARCHAR(8), DATEADD(M, 1, A.PaymentDate), 120)+ '06'
							         ELSE
								         CONVERT(VARCHAR(8), DATEADD(M, 1, A.PaymentDate), 120) + '16'
						            END)
						     END)
					      
						WHEN A.PaymentTypeID =10028 AND  R.AllocateDate IS NOT NULL THEN  	--行動支付 10028 TopUpUsed 儲值消費為即時撥款					    
						      R.AllocateDate 	  
						WHEN A.PaymentTypeID = 10043 AND A.PaymentSubTypeID = 1 THEN		--全家超商手機條碼 APPBarcode Fami 為下下個月底撥款.
							  CONVERT(CHAR(10), DATEADD(MONTH, DATEDIFF(MONTH, -1, A.PaymentDate) + 2, -1), 20) + ' 15:00:00.000' 
					   ELSE
						    (CASE 
                                WHEN CAST(A.PaymentDate AS DATE) >= CAST('2015-01-13' AS DATE)--(2015/1/13 後都改為隔日PM15:00撥款)
								THEN
								      RTRIM(CAST(DATEADD(D, 1, CAST(A.PaymentDate AS DATE)) AS CHAR)) + ' 15:00:00.000'  
							    
								WHEN CAST(A.PaymentDate AS DATE) >= CAST('2015-01-06' AS DATE)--(2015/1/6~1/12 後都改為2015/1/14 PM15:00撥款)
								THEN
								     '2015-01-14 15:00:00.000'																
							    ELSE   				
						          A.PaymentDate + 7
						     END) 
				   END)
			   ELSE
				   NULL
			END AS FundingDate
			--交易待撥金額
			,CASE
				WHEN B.EventCashCostBy = 0 THEN
					CASE
						WHEN A.PaymentTypeID = 10016 OR ISNULL(C.DelayAllocateStatus, 0) > 0 THEN A.TradeTotalAMT - ISNULL(R.ChargeFee, 0) - ISNULL(A.PaymentTypeChargeFee, 0) - ISNULL(B.PlatformChargeFee, 0) - ISNULL(C.RefundAMT, 0) - ISNULL(RedeemAmt,0)
						ELSE A.TradeTotalAMT - ISNULL(R.ChargeFee, 0) - ISNULL(A.PaymentTypeChargeFee, 0) - ISNULL(B.PlatformChargeFee, 0) - ISNULL(RedeemAmt,0)
					END
				ELSE
					CASE
						WHEN A.PaymentTypeID = 10016 OR ISNULL(C.DelayAllocateStatus, 0) > 0 THEN A.TradeTotalAMT - ISNULL(R.ChargeFee, 0) - ISNULL(A.PaymentTypeChargeFee, 0) - ISNULL(B.PlatformChargeFee, 0) - ISNULL(C.RefundAMT, 0)
						ELSE A.TradeTotalAMT - ISNULL(R.ChargeFee, 0) - ISNULL(A.PaymentTypeChargeFee, 0) - ISNULL(B.PlatformChargeFee, 0)
					END
			END AS FundingAMT 
			,J.ExpireDate
			,M.QuickPayType
			,B.QuickPayItemNo
			,B.QuickpayQty			
		    --,(
			--運費
			--CASE 
			--WHEN H.BasicFee IS NOT NULL
			--  THEN 
			--     H.BasicFee
			--WHEN ActualTotalAMT > QPS.RullAmt
		 --      THEN  QPS.RullFee
		 --      ELSE  QPS.BasicFee
		 --    END) AS BasicFee
		    ,QPS_T.BasicFee
			,A.PaymentDate
			,I.Notes
			,I.PaymentSubTypeName
			,M.AddAddressStatus
			,TCD.stage AS TradeInstmt
			,TCD.Redeem
			,A.BalanceAMT
			,C.RefundAMT 
			,C.RefundDate 
			,R.ChargeFee 
			,A.PaymentTypeChargeFee 
			,B.PlatformChargeFee 
			,M.IncludeChargeFeeByBarCode
			,M.IncludeChargeFeeByCode
			,'' as BankCode_eACH --N.BankCode as BankCode_eACH
			,ROUND(ISNULL(RedeemAmt,0),0) AS RedeemAmt --購物金折抵金額
			,ISNULL(A.PlusFeeAmt,0) AS PlusFeeAmt
			,B.BarcodeStoreName
			,B.EventCashCostBy
			,C.AllocateDate AS AlreadyAllocateDate		-- 撥款日期(賣方收到撥款後此欄位才會有值)
			,C.ChargeFeeRate							-- 此筆交易賣方所要負擔的金流手續費率
			,CASE
				WHEN MB.LevelID = 31 THEN '依合約制定'		-- 特店都是鑽石+會員
				ELSE										-- 非鑽石+會員
					CASE 
						WHEN B.TradeType = 'mobile' THEN		-- 行動支付收款
							CASE
								WHEN A.PaymentTypeID = 10000 OR A.PaymentTypeID = 10023 THEN '消費者付款後7天'		-- 信用卡
								WHEN A.PaymentTypeID = 10028 OR A.PaymentTypeID = 10044 THEN '即時撥款'				-- 歐付寶帳戶 & 銀行快付
								ELSE '撥款時間查詢中'
							END
						ELSE									-- 網路購物收款
							CASE
								WHEN A.PaymentTypeID = 10000 OR A.PaymentTypeID = 10023 THEN '消費者付款後7天'		-- 信用卡
								WHEN A.PaymentTypeID = 10044 THEN '即時撥款'											-- 銀行快付
								WHEN A.PaymentTypeID IN (10028, 10001, 10002, 10003, 10005) THEN '付款後隔日'		-- 歐付寶帳戶 & 網路ATM & ATM櫃員機 & 超商代碼
								ELSE '撥款時間查詢中'
							END
					END
			END AS AllocateDateDescr
			,CASE SUBSTRING(E.IDNO, 2, 1)
				WHEN '1' THEN '先生'
				WHEN '2' THEN '小姐'
				ELSE '先生/小姐'
			END AS PayerTitle				-- 付款人稱謂
			,CASE
				WHEN D.LevelID >= 20 THEN IIF(PMD.WebSiteName IS NULL OR PMD.WebSiteName = '', PMD.MerchantName, PMD.WebSiteName) --AND (D.MemberType & 4 = 4 OR D.MemberType & 256 = 256) 
				ELSE NULL
			END AS PayerMerchantName		-- 付款人的商店名稱(商務會員限定)
			,D.LevelID AS PayerLevelID		-- 付款人的會員等級
			,CASE
				WHEN D.LevelID >= 20 THEN PMD.UnifiedBusinessNo --AND (D.MemberType & 4 = 4 OR D.MemberType & 256 = 256)
				ELSE NULL
			END AS BuyerUnifiedBusinessNo	-- 付款人的商店統一編號(商務會員限定)
			,dbo.fn_Decrypt('AES', TCD.EncryptCard4No) AS card4no
	FROM dbo.AllPay_Payment_TradeNo A  WITH(NOLOCK)
	JOIN dbo.AllPay_Payment_TradeDetail B ON A.AllPayTradeID = B.AllPayTradeID
	JOIN dbo.AllPay_Payment_TradeItemsDetail C ON A.AllPayTradeID = C.AllPayTradeID
	LEFT JOIN dbo.AllPay_Payment_TradeDetail_CreditCard TCD ON A.AllPayTradeID = TCD.AllPayTradeID
	LEFT JOIN AllPay.dbo.Member_Basic D ON A.MID = D.MID 	
	LEFT JOIN AllPay.dbo.Member_Detail E ON D.MID = E.MID 		
	LEFT JOIN AllPay.dbo.Member_Basic AS MB WITH(NOLOCK) 
		ON MB.MID = B.MerchantID  				-- 取得收款人的基本資料
	LEFT JOIN [AllPay_PaymentCenter].[dbo].[Payment_MerchantData] AS PMD WITH(NOLOCK)
		ON PMD.MID = A.MID						-- 取得付款人的商店資料
	LEFT JOIN AllPay_Payment_TradeStatusCode F ON A.TradeStatus = F.StatusCode
	LEFT JOIN AllPay_Payment_TradeStatusCode G ON C.ItemStatus = G.StatusCode
	LEFT JOIN dbo.AllPay_Payment_QuickPayShipping H ON A.AllPayTradeID = H.AllPayTradeID AND A.AllPayTradeNo=H.AllPayTradeNo
	LEFT JOIN dbo.AllPay_Payment_TradeSubType I ON A.PaymentTypeID = I.PaymentTypeID AND A.PaymentSubTypeID = I.PaymentSubTypeID
	--改抓 AllPay_Payment_TradeType UpDate 2014-11-12
	LEFT JOIN AllPay_Payment_TradeType T ON A.PaymentTypeID = T.PaymentTypeID		
	LEFT JOIN dbo.AllPay_Payment_TradeDetail_ATM J ON A.AllPayTradeID = J.AllPayTradeID
	LEFT JOIN dbo.AllPay_Payment_TradeDetail_CVS K ON A.AllPayTradeID = K.AllPayTradeID
	--LEFT JOIN dbo.AllPay_Payment_TradeDetail_eACH N ON A.AllPayTradeID = N.AllPayTradeID
	LEFT JOIN dbo.AllPay_Payment_ShipComapny L ON C.ShipCompany = L.CompanyCode
	LEFT JOIN dbo.AllPay_Payment_ShipComapny AS L2 ON H.ShipCompany = L2.CompanyCode
	JOIN (--查詢商品名稱
			SELECT N.AllPayTradeID, MAX(T.BuyerReplyComment) AS BuyerReplyComment	--避免查詢出現多筆，用MAX
					,T.AllocateStatus, T.AllocateDate, MAX(T.ChargeFee) AS ChargeFee
			FROM AllPay_Payment_TradeNo N WITH(NOLOCK)
			JOIN AllPay_Payment_TradeDetail P ON N.AllPayTradeID = P.AllPayTradeID
			JOIN AllPay_Payment_TradeItemsDetail T ON N.AllPayTradeID = T.AllPayTradeID
			WHERE P.MerchantID = @MID AND N.AllPayTradeNo = @allPayTradeNo		
			GROUP BY N.AllPayTradeID,T.AllocateStatus,T.AllocateDate
	) R ON A.AllPayTradeID = R.AllPayTradeID
	LEFT JOIN dbo.AllPay_Payment_QuickPayData M ON M.QuickPayID = B.QuickPayID                --## 快速收款	
	LEFT JOIN dbo.AllPay_Payment_QuickCollectBatchData QB ON A.AllPayTradeNo = QB.AllPayTradeNo 
	LEFT JOIN
	(   --## 計算後運費 update 2015/04/30 by lisa 
	   	SELECT  TOP 1 
     	(CASE 
			WHEN QP.BasicFee IS NOT NULL
			  THEN 
			     QP.BasicFee
			WHEN AA.ActualTotalAMT > QPS.RullAmt
		       THEN  QPS.RullFee
		       ELSE  QPS.BasicFee
		     END) AS BasicFee
			 ,
			 AA.AllPayTradeID
			 From
			 AllPay_Payment_TradeNo AA WITH(NOLOCK),
			 AllPay_Payment_QuickPayShippingCharge QPS,
			 AllPay_Payment_QuickPayShipping QP
			 WHERE AA.AllPayTradeID = QP.AllPayTradeID 			 
			 AND QPS.QuickPayID= QP.QuickPayID
			 AND AA.AllPayTradeNo= @allPayTradeNo
	) QPS_T ON QPS_T.AllPayTradeID = A.AllPayTradeID

	WHERE B.MerchantID = @MID
	AND ISNULL(B.PayUse, 0) <> 2 
	AND	A.AllPayTradeNo = @allPayTradeNo    
	ORDER BY
		A.CreateDate Desc
		
END