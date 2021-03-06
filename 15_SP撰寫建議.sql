-- SP 撰寫建議
-- 以下說明是指許多可能稍微變動參數值即可讓實際執行SQL區塊重複使用
-- 所以需要在變數定義及預設值區塊獨立在最上方
-- 在未來只是變動些條件時(不影響整個邏輯判斷的話)，即可由變數區塊變更預設值即可生效且不需異動實際執行SQL區塊
-- 撰寫時需要注意，避免巢狀迴圈或巢狀判斷 以能在第一層結束就別到第二層
-- 因為在維護修改時常會有人在找END是接哪個IF/While
-- 且在異動資料時減少判斷可增加資料異動的速度(因為少了還要去判斷)
-- 若SP內容有包含transaction 則更需要在異動時才包交易(視情況而定)
-- WHERE後方的條件判斷上 盡量以Index的欄位為主 避免SP中所需執行的內容缺漏Index
-- 除非必要則盡量避免組字串 一方面是組字串很容易引發sql injection及缺漏索引且執行計畫不會被重複使用
-- EXEC(SQL字串) <= 執行計畫不會被重複使用
-- EXEC sp_executesql  <= 執行計畫在微軟聲明中 也僅說明"可能"被重複使用 所以無法控制 這可以幫助開發濾掉不合法的字元避免一些的injection
-- 寧願多寫幾段也不要偷懶求方便通通在同一句SQL (因為DB Engine真的很笨 他不會很聰明地幫你調整)


--SP內容格式
--ALTER PROCEDURE SP名稱
--(
--	參數...
--)
--AS
--BEGIN
	
--	/*
--	--變數定義及預設值區塊
--	*/

--	/*
--	--暫存資料或需先處理的判斷區塊
--	*/

--	/*
--	--實際執行SQL區塊
--	*/
--END


-- SP範例
ALTER PROCEDURE [dbo].[ausp_Sch_AllPay_Payment_Refund_MerchantAllocate]

AS
BEGIN
	
	/*  這個區塊定義變數及預設值 */--------------------------------------------------------------------------
	
	DECLARE  @MerchantID				BIGINT
			,@MerchantTradeNo			VARCHAR(20)
			,@MID						BIGINT
			,@SubTotalAMT				MONEY
			,@AllPayTradeID				BIGINT
			,@AllPayTradeNo				VARCHAR(20)
			,@PaymentTypeID				INT
			,@PaymentSubTypeID			SMALLINT
			,@RtnCode					INT
			,@RtnMsg					VARCHAR(200)
			,@RefundAMT					MONEY		--退款金額
			,@ActualTotalAMT			MONEY = 0	--實際付款金額
			,@ShoppingAMT				MONEY = 0	--購物金金額
			,@ExpireDate				DATETIME = DATEADD(MONTH, 1 , GETDATE())
			,@RealRefundAMT				MONEY = 0	--實際退款金額
			,@RealShoppingAMT			MONEY = 0	--實際退款的購物金金額
			,@BalanceAMT				MONEY = 0	--歐付寶餘額金額
			,@RefundDate				DATETIME	--退款時間
			,@ItemName					NVARCHAR(400)	--商品名稱
			,@TradeTotalAMT				MONEY = 0	--實際付款金額
			,@TimeLine					DATETIME = '2017-05-21' --特定日期
	DECLARE @mail_body			NVARCHAR(MAX)= ''	--## 信件內容 
	DECLARE	@mail_subject		VARCHAR(100)	--## 信件主旨	
	DECLARE	@mail_recipients	VARCHAR(2000)	--## 收件者
	DECLARE	@mail_profile_name	VARCHAR(50)		--## 郵件設定檔名稱	
	DECLARE @RefundMoney MONEY = 0
	DECLARE @MinNo INT
	DECLARE @MaxNo INT

	/********************************
	*	將部分退款剩餘貨款退款給賣家
	********************************/	
	SET @PaymentTypeID = 10013		--退款
	SET @PaymentSubTypeID = 1		--退款


	CREATE TABLE #tempTable
		(	RowNo INT,
			AllPayTradeID BIGINT,
			AllPayTradeNo VARCHAR(20),
			MID	BIGINT,
			MerchantID BIGINT,
			TradeTotalAMT MONEY,
			SubTotalAMT MONEY,
			ActualTotalAMT MONEY,
			PaymentTypeID INT,
			PaymentSubTypeID INT
		)


	/*  暫存資料開始  */--------------------------------------------------------------------------

	--先撈尚未撥款的退款
	CREATE TABLE #TEMP_ChargeBack(	AllPayTradeID BIGINT)

	INSERT INTO #TEMP_ChargeBack
	SELECT DISTINCT AllPayTradeID
	FROM AllPay_Payment_TradeItemsChargeBack WITH(NOLOCK)
	WHERE
		PaymentTypeID <> 10000	--可改為變數定義
	AND
		AllocateDate IS NULL 
	AND
		CreateDate > @TimeLine  -- 這裡是因為有RD告知這裡必須要額外撈取此日期之後的紀錄 與原本之前的應用不同故需要指定


	--撈出部分退款的資料後放入TMEP
	INSERT INTO #tempTable
	SELECT ROW_NUMBER() OVER (ORDER BY A.AllPayTradeID ASC) AS RowNo, 
				A.AllPayTradeID, 
				A.AllPayTradeNo,
				A.MID,
				B.MerchantID,
				A.TradeTotalAMT,
				C.SubTotalAMT,
				A.ActualTotalAMT,
				A.PaymentTypeID,
				A.PaymentSubTypeID
		FROM
			#TEMP_ChargeBack T
		JOIN
			AllPay_Payment_TradeNo A WITH(NOLOCK) ON T.AllPayTradeID = A.AllPayTradeID
		JOIN 
			AllPay_Payment_TradeDetail B WITH(NOLOCK) ON A.AllPayTradeID = B.AllPayTradeID
		JOIN 
			AllPay_Payment_TradeItemsDetail C WITH(NOLOCK) ON A.AllPayTradeID = C.AllPayTradeID
		WHERE
			C.ItemStatus = '3' --部分退款
		AND
			A.PaymentStatus = 1
		AND
			B.MerchantID NOT IN ( --移除POS廠商的交易		
				SELECT MID AS MerchantID
				FROM AllPay_PaymentCenter.dbo.Payment_MerchantData MD WITH(NOLOCK) 
				WHERE ISNULL(IsPOS,0) = 1
			)
		AND NOT EXISTS (
				SELECT 1 FROM
				  AllPay_Payment_MerchantAllocateDay AS d WITH(NOLOCK)
				WHERE d.MID = B.MerchantID
				  AND d.PaymentTypeID NOT IN (10000, 10020, 10021, 10022, 10023, 10026, 10027)	--可改為暫存TABLE
				  AND d.[Status] = 1
				  AND d.HolidayExcepted = 1
				GROUP BY
				  d.MID
			  )

	/*  暫存資料結束  */--------------------------------------------------------------------------




	/*  迴圈執行開始  */--------------------------------------------------------------------------
	--逐筆執行避免資料過大時引發Table Lock
		SELECT	@MinNo = MIN(RowNo),
				@MaxNo = MAX(RowNo)
		FROM #tempTable

	

	WHILE (@MinNo <= @MaxNo)
	BEGIN


			--設定資料
			SELECT 
				@AllPayTradeNo = AllPayTradeNo,
				@MerchantID = MerchantID,
				@TradeTotalAMT = TradeTotalAMT,
				@SubTotalAMT = SubTotalAMT,
				@ActualTotalAMT = ActualTotalAMT
			FROM #tempTable
			WHERE 
				@MinNo = RowNo

		
			--先歸零
			SET @RefundMoney = 0

			--計算需要補撥剩餘款給廠商(需要注意折扣金額是否就是)
			SELECT
				@RefundMoney = SUM( ISNULL(B.ChargeBackAMT,0) )	
			FROM 
				#tempTable tt
		    JOIN
				AllPay_Payment_TradeItemsChargeBack B WITH(NOLOCK) ON tt.AllPayTradeID = B.AllPayTradeID
			WHERE 
				@MinNo = RowNo
			

			--給錢
			IF(@ActualTotalAMT > @RefundMoney)
			BEGIN

						BEGIN
							EXEC	dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo
							@AllpayTradeNo = @AllpayTradeNo OUTPUT
	
							WHILE EXISTS ( SELECT TOP 1 AllPayTradeID FROM dbo.AllPay_Payment_TradeNo WITH (NOLOCK) WHERE AllPayTradeNo = @AllpayTradeNo)
							BEGIN
								EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo
								@AllpayTradeNo = @AllpayTradeNo OUTPUT
							END
				
							IF NOT EXISTS ( SELECT TOP 1 AllPayTradeID FROM dbo.AllPay_Payment_TradeNo WITH (NOLOCK) WHERE AllPayTradeNo = @AllpayTradeNo)
							BEGIN
							
								INSERT INTO dbo.AllPay_Payment_TradeNo (AllPayTradeNo,PaymentTypeID,PaymentSubTypeID,TradeTotalAMT,HandlingCharge,TradeStatus,MID,PaymentStatus,ActualTotalAMT)
			
								VALUES (@AllPayTradeNo,@PaymentTypeID,@PaymentSubTypeID,@TradeTotalAMT,0,1,@MerchantID,1,@TradeTotalAMT)
				
								IF @@ERROR = 0 AND @@ROWCOUNT = 1
								BEGIN
					
									--### 給錢執行這邊
									EXEC	AllPay_Coins.[dbo].[ausp_AllPay_Coins_AddUserCoins_IS]
												@TradeNO			= @AllpayTradeNo,
												@MID				= @MerchantID,
												@Account			= '',
												@MerchantID			= @MerchantID,
												@TradeType			= 10013,
												@TradeSubType		= 1,
												@TradeRealCash		= @RefundMoney,
												@TradeBonusCash		= 0,
												@TradeCreditCash	= 0,
												@TradePayCash		= 0,
												@Currency			= 'TWD',
												@Notes				= '部分退款金額補撥',
												@RtnCode			= @RtnCode  OUTPUT,
												@RtnMsg				= @RtnMsg	OUTPUT,
												@RtnTable			= 0

								END
							END
						END


			END
			ELSE
			BEGIN
					
					SET @mail_body = @mail_body + CAST( @AllpayTradeNo AS VARCHAR)  +','

			END
			

	SET @MinNo	=	@MinNo + 1

	END
	/*  迴圈執行結束  */--------------------------------------------------------------------------


	IF(@mail_body <> '')
	BEGIN
					SET @mail_subject		=	'AllPay_Payment - 部分退款補撥金額錯誤'
					SET @mail_recipients	=	'jarvis.zheng@allpay.com.tw'
					SET @mail_profile_name	=	'adb03_DBA'

					SET @mail_body = '錯誤訂單編號：'+ @mail_body


					--### 寄信錯誤通知				
					EXEC msdb.dbo.sp_send_dbmail
						@profile_name = @mail_profile_name, --信件設定檔名稱
						@recipients = @mail_recipients,		--收信者信件地址
						@body = @mail_body,					--信件內容
						@subject = @mail_subject			--信件主旨

	END


	DROP TABLE #tempTable ,#TEMP_ChargeBack


	


END