USE [AllPay]
GO
/****** Object:  StoredProcedure [dbo].[ausp_Admin_Member_UnLockPayPwdStatus_U]    Script Date: 2017/2/23 下午 01:30:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ausp_Admin_Member_UnLockPayPwdStatus_U]

@MID            BIGINT,
@Note           NVARCHAR(200),
@ModifyUserID   INT = 0
AS

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @RtnCode				BIGINT =-1
	DECLARE @RtnMsg					NVARCHAR(200)='更新狀態失敗'
	DECLARE @intERROR				INT = 0	--記錄錯誤狀態
	DECLARE @PayPWDErrorCounts      INT = 0
	DECLARE @PayPWDErrorCreateDate  DATETIME
	DECLARE @PayPWDErrorLockCounts  INT=0
    
    SELECT	@PayPWDErrorCounts = PayPWDErrorCounts,
			@PayPWDErrorCreateDate = PayPWDErrorCreateDate,
			@PayPWDErrorLockCounts = ISNULL(PayPWDErrorLockCounts,0)
	FROM Member_Login_ErrorStatus WITH(NOLOCK)
	WHERE
	    MID = @MID         
	 
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN	   
		SET @RtnCode =-1
	    SET @RtnMsg = '該會員目前支付密碼未被鎖定'
	    GOTO FINALMSG			   
	END    
	
	--## 先確認是否該會員 支付密碼是鎖定的狀態
	IF NOT (
			   (@PayPWDErrorCounts >=5 AND DATEDIFF(minute, @PayPWDErrorCreateDate, GETDATE()) <= 10 AND @PayPWDErrorLockCounts = 1)	   
			   OR   
			   (@PayPWDErrorCounts >=5 AND DATEDIFF(minute, @PayPWDErrorCreateDate, GETDATE()) <= 60 AND @PayPWDErrorLockCounts > 1)
			)	   	   
	BEGIN
		SET @RtnCode =-2
	    SET @RtnMsg = '該會員目前支付密碼未被鎖定'
	    GOTO FINALMSG			
	END

	--可改為以下寫法  非適用各種狀況
	--IF EXISTS執行階段先確認必要的資料表AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog是否有符合記錄(查詢成本約為0.0088126)
	--若查無記錄則直接返回，若有記錄則往下確認兩張資料表均有更新成功否則回復交易異動
	--交易內確認要更新dbo.Member_Login_ErrorStatus及AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog
	--故以下交易成本皆為必須且少了資料查詢判斷，並不以巢狀寫法避免閱讀不易
	--IF EXISTS執行成本0.0088126
	IF EXISTS (SELECT TOP 1 1 FROM AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog WITH (NOLOCK) WHERE MID = @MID AND LockStatus=1 AND Locktime = @PayPWDErrorCreateDate)
	BEGIN
		SELECT 1
	END
	ELSE
		SET @RtnCode = -3
		GOTO FINALMSG
	END

	BEGIN TRANSACTION
		--執行成本 0.0132842
		UPDATE dbo.Member_Login_ErrorStatus
		SET	PayPWDErrorCounts = 0,
			PayPWDErrorLockCounts = 0
		WHERE
			MID = @MID
		
		IF (@@ERROR <> 0) AND (@@ROWCOUNT <> 1)
		BEGIN
			ROLLBACK TRANSACTION
			SET @RtnCode = -4
			GOTO FINALMSG
		END

		--執行成本0.0183344
		UPDATE AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog
		SET LockStatus = 0,
			UnLocktime = GETDATE(),
			Note=@Note,
			ModifyUserID=@ModifyUserID
		WHERE MID = @MID AND LockStatus=1 AND Locktime = @PayPWDErrorCreateDate 

		IF (@@ERROR <> 0) AND (@@ROWCOUNT <> 1)
		BEGIN
			ROLLBACK TRANSACTION
			SET @RtnCode = -5
			GOTO FINALMSG
		END

	COMMIT TRANSACTION
	SET @RtnCode = 1
	SET @RtnMsg = '成功'
	GOTO FINALMSG
		
	---### 最後回傳的資訊	
	FINALMSG:
	BEGIN				
		SELECT 
			@RtnCode AS RtnCode,	
			@RtnMsg  AS RtnMsg
			
		RETURN						
	END
				
END





