USE [AllPay]
GO
/****** Object:  StoredProcedure [dbo].[ausp_Admin_Member_UnLockPayPwdStatus_U]    Script Date: 2017/2/23 �U�� 01:30:22 ******/
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
	DECLARE @RtnMsg					NVARCHAR(200)='��s���A����'
	DECLARE @intERROR				INT = 0	--�O�����~���A
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
	    SET @RtnMsg = '�ӷ|���ثe��I�K�X���Q��w'
	    GOTO FINALMSG			   
	END    
	
	--## ���T�{�O�_�ӷ|�� ��I�K�X�O��w�����A
	IF NOT (
			   (@PayPWDErrorCounts >=5 AND DATEDIFF(minute, @PayPWDErrorCreateDate, GETDATE()) <= 10 AND @PayPWDErrorLockCounts = 1)	   
			   OR   
			   (@PayPWDErrorCounts >=5 AND DATEDIFF(minute, @PayPWDErrorCreateDate, GETDATE()) <= 60 AND @PayPWDErrorLockCounts > 1)
			)	   	   
	BEGIN
		SET @RtnCode =-2
	    SET @RtnMsg = '�ӷ|���ثe��I�K�X���Q��w'
	    GOTO FINALMSG			
	END

	--�i�אּ�H�U�g�k  �D�A�ΦU�ت��p
	--IF EXISTS���涥�q���T�{���n����ƪ�AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog�O�_���ŦX�O��(�d�ߦ�������0.0088126)
	--�Y�d�L�O���h������^�A�Y���O���h���U�T�{��i��ƪ�����s���\�_�h�^�_�������
	--������T�{�n��sdbo.Member_Login_ErrorStatus��AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog
	--�G�H�U��������Ҭ������B�֤F��Ƭd�ߧP�_�A�ä��H�_���g�k�קK�\Ū����
	--IF EXISTS���榨��0.0088126
	IF EXISTS (SELECT TOP 1 1 FROM AllPay_DataLog.dbo.AllPay_Member_PayPwdLockLog WITH (NOLOCK) WHERE MID = @MID AND LockStatus=1 AND Locktime = @PayPWDErrorCreateDate)
	BEGIN
		SELECT 1
	END
	ELSE
		SET @RtnCode = -3
		GOTO FINALMSG
	END

	BEGIN TRANSACTION
		--���榨�� 0.0132842
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

		--���榨��0.0183344
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
	SET @RtnMsg = '���\'
	GOTO FINALMSG
		
	---### �̫�^�Ǫ���T	
	FINALMSG:
	BEGIN				
		SELECT 
			@RtnCode AS RtnCode,	
			@RtnMsg  AS RtnMsg
			
		RETURN						
	END
				
END





