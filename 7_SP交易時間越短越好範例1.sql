USE [AllPay]
GO
/****** Object:  StoredProcedure [dbo].[ausp_Admin_Member_UnLockPayPwdStatus_U]    Script Date: 2017/3/22 上午 09:57:51 ******/
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
	
	DECLARE @RtnCode		BIGINT =-1
	DECLARE @RtnMsg			NVARCHAR(200)='更新狀態失敗'
	DECLARE @intERROR		INT = 0	--記錄錯誤狀態
	DECLARE @PayPWDErrorCounts      INT = 0,
	        @PayPWDErrorCreateDate  DATETIME,
	        @PayPWDErrorLockCounts  INT=0
    
    SELECT
	     @PayPWDErrorCounts = PayPWDErrorCounts,
	     @PayPWDErrorCreateDate = PayPWDErrorCreateDate,
	     @PayPWDErrorLockCounts = ISNULL(PayPWDErrorLockCounts,0)
	FROM 
	    Member_Login_ErrorStatus WITH(NOLOCK)
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
	   (@PayPWDErrorCounts >=5 AND DATEDIFF(minute, @PayPWDErrorCreateDate, GETDATE()) <= 60 AND @PayPWDErrorLockCounts > 1))	   	   
	BEGIN
	
	     SET @RtnCode =-1
	     SET @RtnMsg = '該會員目前支付密碼未被鎖定'
	     GOTO FINALMSG			
	END
	
	
	--更新鎖定狀態
	BEGIN TRANSACTION

	        UPDATE
				dbo.Member_Login_ErrorStatus
			SET
				PayPWDErrorCounts = 0,
				PayPWDErrorLockCounts = 0
			WHERE
				MID = @MID
			
			IF @@ERROR =0 AND @@ROWCOUNT = 1
			  BEGIN
			   
			        --## 輸入正確 自動解鎖
			        IF EXISTS (SELECT 1 FROM AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog WITH(NOLOCK) WHERE MID = @MID AND LockStatus=1 AND Locktime = @PayPWDErrorCreateDate)
			           BEGIN
			           
			               UPDATE AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog
			               SET LockStatus = 0,
			                   UnLocktime = GETDATE(),
			                   Note=@Note,
			                   ModifyUserID=@ModifyUserID
			               WHERE MID = @MID AND LockStatus=1 AND Locktime = @PayPWDErrorCreateDate    
			               
			               IF @@ERROR = 0 AND @@ROWCOUNT = 1
			                 BEGIN		                 
			                     	SET @RtnCode = 1
	                                SET @RtnMsg = '成功'
	                                COMMIT TRANSACTION

	                                GOTO FINALMSG			                 
			                 END
			               ELSE
	                          BEGIN
	          
	                             ROLLBACK TRANSACTION
                                 SET @RtnCode = -1
	                             SET @RtnMsg = '更新狀態失敗'
	          
	                          END
			           END
			         ELSE
	                    BEGIN
	          
	                       ROLLBACK TRANSACTION
                           SET @RtnCode = -1
	                        SET @RtnMsg = '更新狀態失敗'
	          
	                     END
			      
			  
			  END	
	        ELSE
	          BEGIN
	          
	            ROLLBACK TRANSACTION
                SET @RtnCode = -1
	            SET @RtnMsg = '更新狀態失敗'
	          
	          END
	         
	

		
	---### 最後回傳的資訊	
	FINALMSG:
		BEGIN				
			SELECT 
				@RtnCode AS RtnCode,	
				@RtnMsg  AS RtnMsg								
		END		
			
END





