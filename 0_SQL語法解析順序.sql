-- SQL語法的解析順序
--範例
SELECT 	A.AllPayTradeID, 
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
	B.MerchantID NOT IN () --移除POS廠商的交易

-- 在上方範例中
-- DB最先處理的是
FROM
	#TEMP_ChargeBack T
JOIN
	AllPay_Payment_TradeNo A WITH(NOLOCK)
JOIN 
	AllPay_Payment_TradeDetail B WITH(NOLOCK)
JOIN 
	AllPay_Payment_TradeItemsDetail C WITH(NOLOCK)

-- 接下來處理的是
ON T.AllPayTradeID = A.AllPayTradeID
ON A.AllPayTradeID = B.AllPayTradeID
ON A.AllPayTradeID = C.AllPayTradeID
-- 以及 WHERE後方條件
WHERE
	C.ItemStatus = '3' --部分退款
AND
	A.PaymentStatus = 1
AND
	B.MerchantID NOT IN () --移除POS廠商的交易
-- GROUP BY
-- ORDER BY

-- 接下來處理的是從碟軌區塊中取出真正需要的欄位內容
A.AllPayTradeID, 
A.AllPayTradeNo,
A.MID,
B.MerchantID,
A.TradeTotalAMT,
C.SubTotalAMT,
A.ActualTotalAMT,
A.PaymentTypeID,
A.PaymentSubTypeID

-- 接下來若有GROUP BY 則會先做GROUP
-- 最後就是ORDER BY

-- FROM~WHERE之間先處理 > WHERE條件或JOIN TABLE ON條件 > SELECT Column > GROUP BY > ORDER BY