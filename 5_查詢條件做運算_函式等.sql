-- 以下需要在大量資料的資料表上執行效果較為顯著
-- 以下1&2語法對欄位/參數作運算及3語法先運算好後再執行SQL
-- 執行計畫會有明顯落差
-- 建議盡量少對欄位作運算或使用函式
-- 若使用函式則代表資料表有多少筆資料就需要呼叫多少次Function

--1. 對欄位進行運算
SELECT TOP 1000 [TradeID],
		[TradeNo],
		[amount]
  FROM [AllPay_Credit].[dbo].[o_auth] WITH (NOLOCK)
  WHERE amount * 10 > 100000

--2. 對參數進行運算
SELECT TOP 1000 [TradeID],
		[TradeNo],
		[amount]
  FROM [AllPay_Credit].[dbo].[o_auth] WITH (NOLOCK)
  WHERE amount > 100000 / 10

--3. 先進行運算再進行查詢(查詢anount > 10000)
DECLARE @INT INT
SET @INT = 100000 / 10
SELECT TOP 1000 [TradeID],
		[TradeNo],
		[amount]
  FROM [AllPay_Credit].[dbo].[o_auth] WITH (NOLOCK)
  WHERE amount > @INT

--4. 針對WHERE條件欄位使用轉換函式
DECLARE @Dates DATE
SET @Dates = '2016-07-07'
SELECT TOP 1000 [TradeID],
		[MerchantID]
  FROM [AllPay_Credit].[dbo].[o_auth] WITH (NOLOCK)
  WHERE CAST([MerchantTradeDate] AS VARCHAR) = @Dates

--5. 針對結果集使用函式(資料列多少筆就呼叫多少次)
SELECT	[AllPay_Credit].[dbo].[fn_GetTradeChargeFee]([percen],[GateWayID],[BankTypeID],[TradeAmount],[MinChargeFee]) AS ChargeFee
FROM [AllPay_Credit].[dbo].[o_close] WITH (NOLOCK)
