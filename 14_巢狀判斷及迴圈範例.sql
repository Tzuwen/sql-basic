USE [AllPay_Payment]
GO
/****** Object:  StoredProcedure [dbo].[ausp_Sch_AllPay_Payment_PrePostponeAllocate_I]    Script Date: 2017/7/12 下午 02:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
'程式代號：ausp_Sch_AllPay_Payment_PrePostponeAllocate_I
'程式名稱：
'目　　的：		   
 
'參數說明：
(
	
)
'依存　　：無
'傳回值　：無
'副作用　：無
'備　註　：
'範　例　：


	EXEC	[dbo].[ausp_Sch_AllPay_Payment_PrePostponeAllocate_I]
	
	
'版本變更：
'　xx.  YYYY/MM/DD       VER         AUTHOR          COMMENTS
'  ===  ============    ====        ==========      ==========
'     1. 2014/12/04			        Richard Su	    Create
'     2. 2015/05/26			        Ken Kang		修正錯誤
'     3. 2015/12/18			        Andy Chao		排除停管處，僅寫記錄，不撥信用卡款。
'     4. 2016/04/19			        Jake			排除超商行動支付，不撥信用卡款。
'	  5. 2016/08/12					Jason.chen		增加非延遲撥款資料更新AllPay_Payment_TradeItemsDetail對應單號狀態
'     6. 2016/08/31			        Jake			以Merchant_Data的IsPOS來排除行動支付，不直接寫MerchantID
'     7. 2016/09/30					James Chan		增加撥款後解除退刷圈存處理 => Mantis0014106: 【專法開業】廠商後台_信用卡退刷圈存金額判斷
'     8. 2016/10/01					Andy Chao		因信用卡系統可以撥付未折抵購物金之款項給廠商，所以將北市停管處與POS商的撥款回歸信用卡系統撥款
'     9. 2016/10/03					James Chan		入緩撥的資料加上解除退刷圈存機制
'    10. 2017/01/06					Andy Chao		#1874: 怡客直營店與加盟店皆不撥款
'	 11. 2017/05/02					Hamlet Lin		立即撥款交易撥款狀態回壓到AllPay_PaymentCenter.dbo.Payment_TradeDetail_CreditCard
'	 12. 2017/05/11					Hamlet Lin		修正PaymentCenter撈取資料條件 AllocateStatus <> 1 改為 AllocateStatus ISNULL
'	 13. 2017/05/12					Hamlet Lin		壓入PaymentCenter AllocateDate改為VARCHAR(20)格式存入
'    14. 2017/05/17					Jake	        #6523: 怡客直營店與加盟店恢復撥款
****************************************************************************************/
ALTER PROCEDURE [dbo].[ausp_Sch_AllPay_Payment_PrePostponeAllocate_I]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE
		 @AllPayTradeNo			VARCHAR(20)
		,@PaymentTypeID			INT
		,@PaymentSubTypeID		SMALLINT
		,@FilePath				NVARCHAR(400)
		,@mail_body				NVARCHAR(MAX)
		,@mail_subject			VARCHAR(100)
		,@mail_recipients		VARCHAR(100)
		,@mail_profile_name		VARCHAR(50)
		,@mail_query			VARCHAR(MAX)
		,@execResult			BIT = 0	--### 執行結果
		,@FreezeID              BIGINT      --凍結餘額表主鍵
	    ,@FreezeCash            INT         --凍結金額

	--jason add
	DECLARE @Temp_TotalAmount	BIGINT
	CREATE TABLE #Temp_updateAllocateStat (RowNo INT,AllPayTradeID BIGINT,[Amount] BIGINT)	
	--jason add

	--## Hamlet 新增PaymenrCenter暫存資料
	CREATE TABLE #Temp_updateAllocateStatForPaymentCenter (RowNo INT,TradeID BIGINT,[Amount] BIGINT)

	--### 取出當天的FilePath
	SELECT TOP 1
		@FilePath = XmlFileName 
	FROM 
		dbo.AllPay_Payment_CreditCardWriteOffXml WITH(NOLOCK)
	WHERE 
		CAST(CreateDate AS DATE) = CAST(GETDATE() AS DATE)
	AND
		AllPayTradeNo IS NULL

	--### 將Remark是NULL的XML資料寫到AllPay_Payment_TradeNo
	--### 並透過ausp_AllPay_Coins_AddUserCoins_IS更新特店的金額	
	DECLARE
		 @MyCursor			CURSOR
		,@SeqNo				INT
		,@MerchantID		BIGINT
		,@TotalAmount		MONEY
		,@RtnCode			INT
		,@RtnMsg			VARCHAR(200)
		,@PostponeDays		SMALLINT
		,@RtnMID			BIGINT
		,@TradeDate			VARCHAR(10)
		,@EstimatedDate		VARCHAR(10)
		,@Remark			VARCHAR(200)

	SET @PaymentTypeID = 10010	--### 信用卡收單金額
	SET @PaymentSubTypeID = 1	--### 信用卡收單所得	
	
	SET @MyCursor = CURSOR FAST_FORWARD FOR	
	
		SELECT SeqNo, MerchantID, TotalAmount, TradeDate
		FROM AllPay_Payment_CreditCardWriteOffXml WITH(NOLOCK)
		WHERE
			XmlFileName = @FilePath
		AND Remark IS NULL
		AND AllPayTradeNo IS NULL
		--AND MerchantID NOT IN (1136549,1111405,1143300) --1136549:停管處, 1111405:全家, 1143300:萊爾富
		--AND MerchantID NOT IN (1136549) --1136549:停管處
		--AND MerchantID NOT IN (SELECT MID FROM AllPay_PaymentCenter.dbo.Payment_MerchantData WITH(NOLOCK) WHERE IsPOS = 1)
		/* (已恢復撥款)怡客直營店與加盟店皆不撥款 */
		--AND MerchantID NOT IN (SELECT MID FROM AllPay_Credit.dbo.Credit_MerchantData WITH(NOLOCK) WHERE ISNULL(CreditCardLimitShareMID, MID) = 1396151)

		OPEN @MyCursor FETCH NEXT FROM @MyCursor INTO @SeqNo, @MerchantID, @TotalAmount, @TradeDate

		WHILE @@FETCH_STATUS = 0
		BEGIN
			--### 預設執行失敗(Ken: 2015/05/26)
			SET @execResult = 0

			--### Start 要先判斷張大哥傳進來的 MerchantID 是 MID 還是 GID By Neil 2013/08/14			
			IF LEN(@MerchantID) = 7 OR @MerchantID IN (888891, 888996)
			BEGIN
				SELECT 
					@RtnMID = MID,
					@PostponeDays = PostponeDays
				FROM 
					AllPay_PaymentCenter.dbo.Payment_MerchantToGwCreditMapping WITH(NOLOCK)
				WHERE 
					MID = @MerchantID
			END
			ELSE
			BEGIN
				SELECT 
					@RtnMID = MID,
					@PostponeDays = PostponeDays
				FROM 
					AllPay_PaymentCenter.dbo.Payment_MerchantToGwCreditMapping WITH(NOLOCK)
				WHERE 
					GID = @MerchantID
			END
			
			--### END 要先判斷張大哥傳進來的 MerchantID 是	MID 還是 GID By Neil 2013/08/14		
			
			--### 要檢查是否要延遲撥款
			IF @RtnMID IS NOT NULL AND @PostponeDays > 0
			BEGIN						
				--### 分期撥款(只有遠行旅行社使用)
				IF @RtnMID = 1019086
				BEGIN
					DECLARE
						 @Installment		SMALLINT
						,@I					INT
						,@InstallmentAmt	MONEY
							
					SET @Installment = 2
					SET @I = 1
				
					WHILE @I <= @Installment
					BEGIN
						IF @I = 1
						BEGIN
							SET @PostponeDays = 15
							SET @InstallmentAmt =  CEILING(@TotalAmount * 0.6)
						END
						ELSE
						BEGIN
							SET @PostponeDays = 30
							SET @InstallmentAmt = @TotalAmount - CEILING(@TotalAmount * 0.6)
						END
											
						--### 取得AllPayTradeNo
						EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo @AllPayTradeNo OUTPUT
						
						--### 避免取號重複  2013-11-07 Richard
						WHILE EXISTS (SELECT TOP 1 AllPayTradeID FROM dbo.AllPay_Payment_TradeNo WHERE AllPayTradeNo = @AllPayTradeNo)
						BEGIN
							EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo @AllPayTradeNo OUTPUT
						END
											
						--### 新增訂單資訊
						INSERT INTO dbo.AllPay_Payment_TradeNo
							(
								AllPayTradeNo, PaymentTypeID, PaymentSubTypeID, TradeTotalAMT, HandlingCharge
								, CreateDate, TradeStatus, MID, PaymentStatus, ActualTotalAMT
							)
						VALUES
							(	
								@AllPayTradeNo, @PaymentTypeID, @PaymentSubTypeID, @InstallmentAmt, 0
								, GETDATE(), 0, @RtnMID, 0, @InstallmentAmt
							)
										
						IF @@ERROR = 0 AND @@ROWCOUNT = 1
						BEGIN
							--### 設定預計撥款日期
							SET @EstimatedDate = CONVERT(VARCHAR(10), GETDATE() + @PostponeDays, 111)
									
							--### 新增緩撥資料
							INSERT INTO dbo.AllPay_Payment_PostponeAllocateData_CreditCard
								(
									MerchantID, GID, WriteOffSeqNo, AllPayTradeNo, TradeDate, TotalAmount, EstimatedDate, Remark
								)
							VALUES
								(
									@RtnMID, @MerchantID, @SeqNo, @AllPayTradeNo, @TradeDate, @InstallmentAmt, @EstimatedDate, '延遲撥款(分期' + CONVERT(VARCHAR(2), @I) + ')|'
								)
												
							--### 判斷成功還失敗
							IF @@ERROR = 0 AND @@ROWCOUNT = 1
							BEGIN
								SET @execResult = 1
								SET @Remark = '新增延遲撥款(分期' + CONVERT(VARCHAR(2), @I) + ')'
							END
							ELSE
							BEGIN
								SET @execResult = 0
								SET @Remark = '延遲撥款失敗(分期' + CONVERT(VARCHAR(2), @I) + ')'
							END
														
							--### 更新XML資料
							UPDATE 
								AllPay_Payment_CreditCardWriteOffXml
							SET 
								AllPayTradeNo = @AllPayTradeNo,
								Remark = @Remark
							WHERE 
								SeqNo = @SeqNo
														
							IF @@ERROR = 0 AND @@ROWCOUNT = 1 AND @execResult = 1
							BEGIN
								EXEC	AllPay_Coins.dbo.ausp_AllPay_Coins_AddUserCoins_IS 
										@TradeNO			= @AllPayTradeNo,
										@MID				= @RtnMID,
										@Account			= '',
										@MerchantID         = @RtnMID,
										@TradeType			= @PaymentTypeID,
										@TradeSubType		= @PaymentSubTypeID,
										@TradeRealCash		= 0,
										@TradeBonusCash		= 0,
										@TradeCreditCash	= 0,
										@TradePayCash		= 0,
										@Currency			= 'TWD',
										@Notes				= '信用卡收單所得_延遲撥款',
										@RtnCode			= @RtnCode	OUTPUT,
										@RtnMsg				= @RtnMsg	OUTPUT,
										@RtnTable			= 1,
										@TradePostponeCash  = @InstallmentAmt
						
								--### 失敗則發Mail
								IF @RtnCode <> 1 
								BEGIN
									SET @mail_profile_name = N'adb05_DBA'
									SET @mail_recipients = N'sys-error@allpay.com.tw'
									SET @mail_subject = N'嚴重問題(請通知人員) : Credit Card : ausp_AllPay_Coins_AddUserCoins_IS 執行失敗'
									SET @mail_body = '錯誤代碼: ' + CAST(@RtnCode AS VARCHAR) + CHAR(10) + '錯誤訊息: ' + @RtnMsg + CHAR(10)
														+'MerchantID: ' + CAST(@MerchantID AS VARCHAR) + CHAR(10)
														+'金額: ' + CAST(@InstallmentAmt AS VARCHAR)
										 
									EXEC	msdb.dbo.sp_send_dbmail
											@profile_name = @mail_profile_name,
											@recipients = @mail_recipients,
											@body = @mail_body,
											@body_format = 'TEXT',
											@subject = @mail_subject
								END
								ELSE  --### 成功則執行解除退刷圈存動作
								BEGIN

								  DECLARE @RefundInstallmentPostponeCursor CURSOR
									  SET @RefundInstallmentPostponeCursor = CURSOR FAST_FORWARD FOR
											   SELECT FC.FreezeID,FC.FreezeCash
												 FROM AllPay_Credit.dbo.o_close OC WITH(NOLOCK)
										   INNER JOIN AllPay_Credit.dbo.Credit_RefundBlockRelation RBR WITH(NOLOCK)
												   ON RBR.sr = OC.sr
										   INNER JOIN AllPay_Coins.dbo.AllPay_FreezeCoins FC WITH(NOLOCK)
												   ON FC.FreezeID = RBR.FreezeID
										   INNER JOIN AllPay_Credit.dbo.Credit_MerchantData cmd WITH(NOLOCK)
												   ON cmd.MID = oc.MerchantID
												WHERE OC.MerchantID = @MerchantID
												  AND OC.taishin <= CONVERT(VARCHAR(10),@TradeDate,111)
												  AND FC.Status = 1
				             
								   OPEN @RefundInstallmentPostponeCursor FETCH NEXT FROM @RefundInstallmentPostponeCursor INTO @FreezeID,@FreezeCash
									 WHILE @@FETCH_STATUS = 0
									   BEGIN
		               
										 EXEC AllPay_Coins.dbo.ausp_Admin_Coins_UpdateFreezeCash_U @MerchantID,@FreezeID,@FreezeCash,3,'該筆退刷款項已完成撥款，系統已解除凍結','系統解除',NULL
                         
										 FETCH NEXT FROM @RefundInstallmentPostponeCursor INTO @FreezeID,@FreezeCash
									   END
								   CLOSE @RefundInstallmentPostponeCursor
								   DEALLOCATE @RefundInstallmentPostponeCursor

								END
							END	
						END

						SET @I = @I + 1 
					END								
				END
				ELSE
				BEGIN
					--### 要延遲撥款的會跑這邊，取號DELAY0.5秒
					WAITFOR DELAY '00:00:00.500'
										
					--### 取得AllPayTradeNo
					EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo @AllPayTradeNo OUTPUT
									
					--### 避免取號重複  2013-11-07 Richard
					WHILE EXISTS (SELECT TOP 1 AllPayTradeID FROM dbo.AllPay_Payment_TradeNo WHERE AllPayTradeNo = @AllPayTradeNo)
					BEGIN
						EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo @AllPayTradeNo OUTPUT
					END
									
					--### 新增訂單資訊
					INSERT INTO dbo.AllPay_Payment_TradeNo
						(
							AllPayTradeNo, PaymentTypeID, PaymentSubTypeID, TradeTotalAMT, HandlingCharge
							, CreateDate, TradeStatus, MID, PaymentStatus, ActualTotalAMT
						)
					VALUES
						(	
							@AllPayTradeNo, @PaymentTypeID, @PaymentSubTypeID, @TotalAmount, 0
							, GETDATE(), 0, @RtnMID, 0, @TotalAmount
						)
										
					IF @@ERROR = 0 AND @@ROWCOUNT = 1
					BEGIN
						--### 設定預計撥款日期
						SET @EstimatedDate = CONVERT(VARCHAR(10), GETDATE() + @PostponeDays, 111)
									
						--### 新增緩撥資料
						INSERT INTO dbo.AllPay_Payment_PostponeAllocateData_CreditCard
							(
								MerchantID, GID, WriteOffSeqNo, AllPayTradeNo, TradeDate, TotalAmount, EstimatedDate, Remark
							)
						VALUES
							(
								@RtnMID, @MerchantID, @SeqNo, @AllPayTradeNo, @TradeDate, @TotalAmount, @EstimatedDate, '延遲撥款|'
							)
										
						--### 判斷成功還失敗
						IF @@ERROR = 0 AND @@ROWCOUNT = 1
						BEGIN
							SET @execResult = 1
							SET @Remark = '新增延遲撥款'
						END
						ELSE
						BEGIN
							SET @execResult = 0
							SET @Remark = '延遲撥款失敗'
						END
												
						--### 更新XML資料
						UPDATE 
							AllPay_Payment_CreditCardWriteOffXml
						SET 
							AllPayTradeNo = @AllPayTradeNo,
							Remark = @Remark
						WHERE 
							SeqNo = @SeqNo
												
						IF @@ERROR = 0 AND @@ROWCOUNT = 1 AND @execResult = 1
						BEGIN
							EXEC	AllPay_Coins.dbo.ausp_AllPay_Coins_AddUserCoins_IS 
									@TradeNO			= @AllPayTradeNo,
									@MID				= @RtnMID,
									@Account			= '',
									@MerchantID         = @RtnMID,
									@TradeType			= @PaymentTypeID,
									@TradeSubType		= @PaymentSubTypeID,
									@TradeRealCash		= 0,
									@TradeBonusCash		= 0,
									@TradeCreditCash	= 0,
									@TradePayCash		= 0,
									@Currency			= 'TWD',
									@Notes				= '信用卡收單所得_延遲撥款',
									@RtnCode			= @RtnCode	OUTPUT,
									@RtnMsg				= @RtnMsg	OUTPUT,
									@RtnTable			= 1,
									@TradePostponeCash  = @TotalAmount
														
							--### 失敗則發Mail
							IF @RtnCode <> 1 
							BEGIN
								SET @mail_profile_name = N'adb05_DBA'
								SET @mail_recipients = N'sys-error@allpay.com.tw'
								SET @mail_subject = N'嚴重問題(請通知人員) : Credit Card : ausp_AllPay_Coins_AddUserCoins_IS 執行失敗'
								SET @mail_body = '錯誤代碼: ' + CAST(@RtnCode AS VARCHAR) + CHAR(10) + '錯誤訊息: ' + @RtnMsg + CHAR(10)
												+'MerchantID: ' + CAST(@MerchantID AS VARCHAR) + CHAR(10)
												+'金額: ' + CAST(@TotalAmount AS VARCHAR)
					 
								EXEC	msdb.dbo.sp_send_dbmail
										@profile_name = @mail_profile_name,
										@recipients = @mail_recipients,
										@body = @mail_body,
										@body_format = 'TEXT',
										@subject = @mail_subject
							END
							ELSE  --### 成功則執行解除退刷圈存動作
							BEGIN

							  DECLARE @RefundPostponeCursor CURSOR
								  SET @RefundPostponeCursor = CURSOR FAST_FORWARD FOR
										   SELECT FC.FreezeID,FC.FreezeCash
											 FROM AllPay_Credit.dbo.o_close OC WITH(NOLOCK)
									   INNER JOIN AllPay_Credit.dbo.Credit_RefundBlockRelation RBR WITH(NOLOCK)
											   ON RBR.sr = OC.sr
									   INNER JOIN AllPay_Coins.dbo.AllPay_FreezeCoins FC WITH(NOLOCK)
											   ON FC.FreezeID = RBR.FreezeID
									   INNER JOIN AllPay_Credit.dbo.Credit_MerchantData cmd WITH(NOLOCK)
											   ON cmd.MID = oc.MerchantID
											WHERE OC.MerchantID = @MerchantID
											  AND OC.taishin <= CONVERT(VARCHAR(10),@TradeDate,111)
											  AND FC.Status = 1
				             
							   OPEN @RefundPostponeCursor FETCH NEXT FROM @RefundPostponeCursor INTO @FreezeID,@FreezeCash
								 WHILE @@FETCH_STATUS = 0
								   BEGIN
		               
									 EXEC AllPay_Coins.dbo.ausp_Admin_Coins_UpdateFreezeCash_U @MerchantID,@FreezeID,@FreezeCash,3,'該筆退刷款項已完成撥款，系統已解除凍結','系統解除',NULL
                         
									 FETCH NEXT FROM @RefundPostponeCursor INTO @FreezeID,@FreezeCash
								   END
							   CLOSE @RefundPostponeCursor
							   DEALLOCATE @RefundPostponeCursor

							END
						END	
					END
				END
			END
			ELSE
			BEGIN
				--### 沒有撈到 或 延遲撥款天期為 0 則直接撥款
					
				--### 張大哥只傳 GID，所以要把 @MerchantID 換掉
				IF @RtnMID IS NOT NULL
				BEGIN		
					SET @MerchantID = @RtnMID
				END

				--### 取得AllPayTradeNo
				EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo @AllPayTradeNo OUTPUT

				--### 避免取號重複  2013-11-07 Richard
				WHILE EXISTS (SELECT TOP 1 AllPayTradeID FROM dbo.AllPay_Payment_TradeNo WHERE AllPayTradeNo = @AllPayTradeNo)
				BEGIN
					EXEC dbo.ausp_AllPay_Payment_GetAllPayRandTradeNo @AllPayTradeNo OUTPUT
				END

				--### 新增訂單資料
				INSERT INTO dbo.AllPay_Payment_TradeNo
					(
						AllPayTradeNo, PaymentTypeID, PaymentSubTypeID, TradeTotalAMT, HandlingCharge
						, CreateDate, TradeStatus, MID, PaymentStatus, ActualTotalAMT
					)
				VALUES
					(	
						@AllPayTradeNo, @PaymentTypeID, @PaymentSubTypeID, @TotalAmount, 0
						, GETDATE(), 0, @MerchantID, 0, @TotalAmount
					)
								
				IF (@@ROWCOUNT = 1 AND @@ERROR = 0)
				BEGIN			
					--### 更新XML資料的AllPayTradeNo
					UPDATE AllPay_Payment_CreditCardWriteOffXml
					SET AllPayTradeNo = @AllPayTradeNo
					WHERE SeqNo = @SeqNo

					IF(@@ROWCOUNT = 1 AND @@ERROR = 0)
					BEGIN
						EXEC	AllPay_Coins.dbo.ausp_AllPay_Coins_AddUserCoins_IS 
								@TradeNO			= @AllPayTradeNo,
								@MID				= @MerchantID,
								@Account			= '',
								@MerchantID         = @MerchantID,
								@TradeType			= @PaymentTypeID,
								@TradeSubType		= @PaymentSubTypeID,
								@TradeRealCash		= 0,
								@TradeBonusCash		= 0,
								@TradeCreditCash	= @TotalAmount,
								@TradePayCash		= 0,
								@Currency			= 'TWD',
								@Notes				= '信用卡收單所得',
								@RtnCode			= @RtnCode	OUTPUT,
								@RtnMsg				= @RtnMsg	OUTPUT

						DECLARE @Temp_TradeDate_xmldetail DATE
						DECLARE @Temp_AllocateDate DATETIME

						SET @Temp_TotalAmount = @TotalAmount

						--取[AllPay_Payment].dbo.AllPay_Payment_CreditCardWriteOffXml中對應的TradeDate
						SELECT	@Temp_TradeDate_xmldetail = DATEFROMPARTS(CAST(LEFT(TradeDate,4) AS INT),CAST(SUBSTRING(TradeDate,5,2) AS INT),CAST(RIGHT(TradeDate,2) AS INT)),
								@Temp_AllocateDate = GETDATE()
						FROM [AllPay_Payment].dbo.AllPay_Payment_CreditCardWriteOffXml WITH (NOLOCK)
						WHERE
							@SeqNo = SeqNo
							--AND [AllocateStatus] = 1

						IF (@RtnCode = 1 AND @Temp_TotalAmount > 0)
						BEGIN
							DECLARE @MinNo	INT
							DECLARE @MaxNo	INT
							DECLARE @Temp_AllPayTradeID	BIGINT
							DECLARE @Temp_Detail_Amount BIGINT

							TRUNCATE TABLE #Temp_updateAllocateStat

							--暫存每筆撥款資料對應的訂單
							INSERT INTO #Temp_updateAllocateStat
							SELECT	ROW_NUMBER() OVER (ORDER BY AllPayTradeID ASC) AS RowNo,
									AllPayTradeID,
									A.[Amount]
							FROM [AllPay_Credit].[dbo].[pay_xml_detail] AS A WITH (NOLOCK)
								INNER JOIN [AllPay_Payment].[dbo].[AllPay_Payment_TradeDetail_CreditCard] AS B WITH (NOLOCK)
									 ON A.[TradeID] = B.gwsr
							WHERE
								@MerchantID = A.MerchantID
								AND @Temp_TradeDate_xmldetail = A.TradeDate
								AND A.[Amount] > 0
					
							SELECT	@MinNo = MIN(RowNo),
									@MaxNo = MAX(RowNo)
							FROM #Temp_updateAllocateStat
					
							-- 逐筆更新
							WHILE (@MinNo <= @MaxNo)
							BEGIN
								SELECT	@Temp_AllPayTradeID = AllPayTradeID,
										@Temp_Detail_Amount = [Amount]
								FROM #Temp_updateAllocateStat
								WHERE
									@MinNo = RowNo

								IF (@Temp_Detail_Amount > 0)
								BEGIN
									UPDATE [AllPay_Payment].[dbo].[AllPay_Payment_TradeItemsDetail]
									SET	[AllocateStatus] = 1,
										[AllocateDate] = @Temp_AllocateDate
									WHERE
										@Temp_AllPayTradeID = AllPayTradeID
										AND AllocateStatus <> 1
										AND AllocateDate IS NULL
								END

								SET @MinNo = @MinNo + 1
							END -- End While


							--## 新增撥款狀態回壓PaymentCenter Start--------------------------------------------------------------------
							TRUNCATE TABLE #Temp_updateAllocateStatForPaymentCenter

							--暫存每筆撥款資料對應的訂單回壓PaymentCenter
							INSERT INTO #Temp_updateAllocateStatForPaymentCenter
							SELECT	ROW_NUMBER() OVER (ORDER BY A.TradeID ASC) AS RowNo,
									A.TradeID,
									A.[Amount]
							FROM [AllPay_Credit].[dbo].[pay_xml_detail] AS A WITH (NOLOCK)
							INNER JOIN AllPay_PaymentCenter.dbo.Payment_TradeDetail_CreditCard AS B WITH (NOLOCK)
							ON A.[TradeID] = B.gwsr
							WHERE
								@MerchantID = A.MerchantID
							AND 
								@Temp_TradeDate_xmldetail = A.TradeDate
							AND 
								A.[Amount] > 0

							SELECT	@MinNo = MIN(RowNo),
									@MaxNo = MAX(RowNo)
							FROM #Temp_updateAllocateStatForPaymentCenter

							WHILE (@MinNo <= @MaxNo)
							BEGIN
								SELECT	@Temp_AllPayTradeID = TradeID,
										@Temp_Detail_Amount = [Amount]
								FROM #Temp_updateAllocateStatForPaymentCenter
								WHERE
									@MinNo = RowNo

								IF (@Temp_Detail_Amount > 0)
								BEGIN
									UPDATE AllPay_PaymentCenter.dbo.Payment_TradeDetail_CreditCard
									SET	[AllocateStatus] = 1,
										[AllocateDate] = CONVERT(VARCHAR(19),@Temp_AllocateDate, 120)
									WHERE
										gwsr = @Temp_AllPayTradeID
										AND AllocateStatus IS NULL
										AND AllocateDate IS NULL
								END

								SET @MinNo = @MinNo + 1
							END -- End While
							--## 新增撥款狀態回壓PaymentCenter End--------------------------------------------------------------------
						END -- End IF
							
						--### 失敗則發Mail
						IF @RtnCode <> 1 
						BEGIN
							SET @mail_profile_name = N'adb05_DBA'
							SET @mail_recipients = N'sys-error@allpay.com.tw'
							SET @mail_subject = N'嚴重問題(請通知人員) : Credit Card : ausp_AllPay_Coins_AddUserCoins_IS 執行失敗'
							SET @mail_body = '錯誤代碼: ' + CAST(@RtnCode AS VARCHAR) + CHAR(10) + '錯誤訊息: ' + @RtnMsg + CHAR(10)
											+'MerchantID: ' + CAST(@MerchantID AS VARCHAR) + CHAR(10)
											+'金額: ' + CAST(@TotalAmount AS VARCHAR)
												 
							EXEC	msdb.dbo.sp_send_dbmail
									@profile_name = @mail_profile_name,
									@recipients = @mail_recipients,
									@body = @mail_body,
									@body_format = 'TEXT',
									@subject = @mail_subject
				
						END
						ELSE  --### 成功則執行解除退刷圈存動作
						BEGIN

						  DECLARE @RefundCursor CURSOR
							  SET @RefundCursor = CURSOR FAST_FORWARD FOR
									   SELECT FC.FreezeID,FC.FreezeCash
										 FROM AllPay_Credit.dbo.o_close OC WITH(NOLOCK)
								   INNER JOIN AllPay_Credit.dbo.Credit_RefundBlockRelation RBR WITH(NOLOCK)
										   ON RBR.sr = OC.sr
								   INNER JOIN AllPay_Coins.dbo.AllPay_FreezeCoins FC WITH(NOLOCK)
										   ON FC.FreezeID = RBR.FreezeID
								   INNER JOIN AllPay_Credit.dbo.Credit_MerchantData cmd WITH(NOLOCK)
								           ON cmd.MID = oc.MerchantID
										WHERE OC.MerchantID = @MerchantID
										  AND DATEDIFF(DAY, OC.taishin, DATEADD(DAY, - ISNULL(cmd.CreditCardAllocateDay, 0), GETDATE() - 0)) = 0	--##撥款日期 等於 現在日期-撥款天數
										  AND FC.Status = 1
				             
						   OPEN @RefundCursor FETCH NEXT FROM @RefundCursor INTO @FreezeID,@FreezeCash
							 WHILE @@FETCH_STATUS = 0
							   BEGIN
		               
								 EXEC AllPay_Coins.dbo.ausp_Admin_Coins_UpdateFreezeCash_U @MerchantID,@FreezeID,@FreezeCash,3,'該筆退刷款項已完成撥款，系統已解除凍結','系統解除',NULL
                         
								 FETCH NEXT FROM @RefundCursor INTO @FreezeID,@FreezeCash
							   END
						   CLOSE @RefundCursor
						   DEALLOCATE @RefundCursor

						END

					END
				END
			END

			FETCH NEXT FROM @MyCursor INTO @SeqNo, @MerchantID, @TotalAmount, @TradeDate
		END
	CLOSE @MyCursor
	DEALLOCATE @MyCursor
	
	SELECT '1','已轉入'
END