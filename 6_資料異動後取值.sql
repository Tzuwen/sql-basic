-- 異動後需取回更新內容
-- 因常有需要進行資料更新後取值可改用以下方式
--舊寫法如下
DECLARE @AllPayTradeID		BIGINT
DECLARE @TradeInstmt		MONEY
DECLARE @InstallmentAmount	MONEY

UPDATE dbo.AllPay_Payment_TradeDetail
SET TradeInstmt = 0,
	InstallmentAmount = 0
WHERE
	AllPayTradeID= @AllPayTradeID

SELECT	@TradeInstmt = TradeInstmt,
		@InstallmentAmount = InstallmentAmount  
FROM dbo.AllPay_Payment_TradeDetail WITH(NOLOCK) 
WHERE
	AllPayTradeID= @AllPayTradeID

--建議寫法如下
DECLARE @AllPayTradeID		BIGINT
DECLARE @TradeInstmt		MONEY
DECLARE @InstallmentAmount	MONEY

DECLARE @Temp_Amount	TABLE (TradeInstmt MONEY,InstallmentAmount MONEY)

UPDATE dbo.AllPay_Payment_TradeDetail
SET TradeInstmt = 0,
	InstallmentAmount = 0
OUTPUT INSERTED.TradeInstmt,INSERTED.InstallmentAmount INTO @Temp_Amount
WHERE
	AllPayTradeID= @AllPayTradeID

SELECT	@TradeInstmt = TradeInstmt,
		@InstallmentAmount = InstallmentAmount  
FROM @Temp_Amount

--撰寫時得多寫一些內容
--原理是PK在怎麼快畢竟是在實體TABLE上且異動資料時DB Engine本來就會先做DELETE再做INSERT的動作
--記憶體TABLE會占用記憶體 但執行速度快且執行完即釋放  少數幾筆資料時可使用
--沒必要進實體TABLE就減少進入機會

--以下為新增資料時的取值方式
INSERT INTO dbo.AllPay_Payment_TradeDetail
	(AllPayTradeID,TradeInstmt,InstallmentAmount)
OUTPUT INSERTED.TradeInstmt,INSERTED.InstallmentAmount INTO @Temp_Amount
VALUES
	(@AllPayTradeID,@TradeInstmt,@InstallmentAmount)

SELECT	@TradeInstmt = TradeInstmt,
		@InstallmentAmount = InstallmentAmount  
FROM @Temp_Amount

--以下為刪除後取值
DELETE FROM dbo.AllPay_Payment_TradeDetail
OUTPUT DELETED.TradeInstmt,DELETED.InstallmentAmount INTO @Temp_Amount
WHERE
	AllPayTradeID= @AllPayTradeID

SELECT	@TradeInstmt = TradeInstmt,
		@InstallmentAmount = InstallmentAmount  
FROM @Temp_Amount

--額外補充 舊語法中
UPDATE dbo.AllPay_Payment_TradeDetail
SET TradeInstmt = 0,		-- 更新為0
	InstallmentAmount = 0	-- 更新為0
WHERE
	AllPayTradeID= @AllPayTradeID

SELECT	@TradeInstmt = TradeInstmt,
		@InstallmentAmount = InstallmentAmount  
FROM dbo.AllPay_Payment_TradeDetail WITH(NOLOCK) 
WHERE
	AllPayTradeID= @AllPayTradeID -- <= 與上面UPDATE語法為同一筆資料

--既已更新為0  為何還需要進同一張TABLE再取一次資料?  可直接設定為0吧
