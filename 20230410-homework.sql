-- 找出和最貴的產品同類別的所有產品
select CategoryID,max(UnitPrice) as MostExpensive
from Products
group by CategoryID;
-- 找出和最貴的產品同類別最便宜的產品
select 
	CategoryID,
	max(UnitPrice) as MostExpensive, 
	min(UnitPrice) as MostCheapest
from Products
group by CategoryID;
-- 計算出上面類別最貴和最便宜的兩個產品的價差
with CheapExp as (
	select 
		CategoryID,
		max(UnitPrice) as MostExpensive, 
		min(UnitPrice) as MostCheapest
	from Products
	group by CategoryID
)select 
	CategoryID,
	MostExpensive-MostCheapest as PriceDeviation
from CheapExp;
-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶
select CustomerID,City
from Customers c
where (not exists(select * from Orders o where (o.CustomerID=c.CustomerID)));
-- 找出第 5 貴跟第 8 便宜的產品的產品類別

--create or alter function Forder1()
--returns table as
--return
--	select 
--		row_number() over (order by UnitPrice) as col,
--		ProductID,
--		CategoryID,
--		ProductName,
--		UnitPrice
--	from Products
--go;

select CategoryID
from Forder1() p
where (p.col in (
	8,
	(select count(ProductID)	as county
	from Products)-7)
);
-- 找出誰買過第 5 貴跟第 8 便宜的產品
select ProductID,ProductName
from Forder1() p
where (p.col in (
	8,
	(select count(ProductID) as county
	from Products)-7)
);
-- 找出誰賣過第 5 貴跟第 8 便宜的產品
with p58 as (
	select ProductID,ProductName
	from Forder1() p
	where (p.col in (
		8,
		(select count(ProductID) as county
		 from Products)-7)
	)
)
select distinct c.CustomerID,c.ContactName
from Customers c
inner join Orders o on (o.CustomerID=c.CustomerID)
inner join [Order Details] od on (od.OrderID=o.OrderID)
where (od.ProductID = any(select ProductID from p58));

-- 找出 13 號星期五的訂單 (惡魔的訂單)
select OrderID,OrderDate,CustomerID,EmployeeID 
from [orders] 
where (
	day([OrderDate])=13
	and
	datepart(weekday,[OrderDate])=5
);
-- 找出誰訂了惡魔的訂單
with dfri as (
	select * 
	from [orders] 
	where (
		day([OrderDate])=13
		and
		datepart(weekday,[OrderDate])=5
	)
)
select c.CustomerID,c.ContactName,o.OrderDate
from [Customers] c
inner join dfri o on (c.CustomerID=o.CustomerID);
-- 找出惡魔的訂單裡有什麼產品
select distinct p.ProductID,p.ProductName,o.OrderDate 
from Products p
inner join [Order Details] od on (od.ProductID=p.ProductID)
inner join Orders o on (o.OrderID=od.OrderID)
where (
	o.OrderID=any(
		select OrderID 
		from [orders] 
		where (
			day([OrderDate])=13
			and
			datepart(weekday,[OrderDate])=5
		)
	)
);
-- 列出從來沒有打折 (Discount) 出售的產品
select distinct p.ProductID,p.ProductName,od.Discount
from Products p
inner join [Order Details] od on (od.ProductID=p.ProductID)
where (od.Discount=0);
-- 列出購買非本國的產品的客戶
select distinct c.CustomerID,c.ContactTitle,c.Country,s.SupplierID,s.ContactName,s.Country 
from Customers c
inner join Orders o on (o.CustomerID=c.CustomerID)
inner join [Order Details] od on (od.OrderID=o.OrderID)
inner join Products p on (p.ProductID=od.ProductID)
inner join Suppliers s on (s.SupplierID=p.SupplierID)
where (s.Country<>c.Country);
-- 列出在同個城市中有公司員工可以服務的客戶
select 
	c.CustomerID , c.ContactName ,
	c.City as CustomerCity,
	e.City as EmployeeCity
from Customers c
inner join Employees e on (e.City=c.City);
-- 列出那些產品沒有人買過
select distinct p.ProductID,p.ProductName
from Products p
where (not exists(select * from [Order Details] where (ProductID=p.ProductID)));
----------------------------------------------------------------------------------------
-- 列出所有在每個月月底的訂單
select OrderID , OrderDate , CustomerID
from Orders where OrderDate=EOMONTH(OrderDate);
-- 列出每個月月底售出的產品
with endmonth as (
	select OrderID from Orders where OrderDate=EOMONTH(OrderDate)
)select distinct p.ProductID,p.ProductName,o.OrderDate 
from Products p
inner join [Order Details] od on (od.ProductID=p.ProductID)
inner join Orders o on (o.OrderID=od.OrderID)
where (o.OrderID=any(select OrderID from endmonth));
-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶
with exp3 as (
	select ProductID
	from Products
	order by UnitPrice desc
	offset 0 rows
	fetch next 3 rows only
),
t1 as (
	select
		row_number() over (order by p.ProductID) as RowNum,
		c.CustomerID,c.ContactName,p.ProductID 
	from Customers c
	inner join Orders o on (o.CustomerID=c.CustomerID)
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	inner join Products p on (p.ProductID=od.ProductID)
	where (p.ProductID=any(select ProductID from exp3))
),
t2 as (
	select max(RowNum) as m,ProductID
	from t1
	group by ProductID
)
select CustomerID,ContactName,ProductID
from t1
where (RowNum=any(select m from t2));	
-- 找出有敗過銷售金額前三高個產品的前三個大客戶
select distinct top 3
	c.CustomerID,c.CompanyName,
	sum(od.UnitPrice*od.Quantity*(1-od.Discount))as SalesAmount
from Customers c
inner join Orders o on (o.CustomerID=c.CustomerID)
inner join [Order Details] od on (od.OrderID=o.OrderID)
where od.ProductID in (
	select top 3
		od.ProductID
	from [Order Details] od
	group by od.ProductID
	order by sum((od.UnitPrice*od.Quantity)*(1-od.Discount)) desc
)
group by c.CustomerID,c.CompanyName
order by SalesAmount desc;
-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶
with t1 as (
	select 
		UnitPrice*(1-Discount)*Quantity as OrderPrice,
		ProductID
	from [Order Details]
),
t2 as (
	select top 3 ProductID,sum(OrderPrice) as Revenue
	from t1
	group by ProductID
	order by Revenue desc
),
t3 as (
	select
		row_number() over (order by od.ProductID ,od.Quantity) as RowNum,
		c.CustomerID,c.ContactName,od.ProductID,od.Quantity
	from Customers c
	inner join Orders o on (o.CustomerID=c.CustomerID)
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	where (od.ProductID=any(select ProductID from t2))
),
t4 as (
	select max(RowNum) as Top3P
	from t3
	group by ProductID
)
select p.CategoryID,CustomerID,ContactName,t3.ProductID,Quantity  
from t3
inner join Products p on (p.ProductID=t3.ProductID)
where (RowNum=any(select Top3P from t4));
-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額
with t1 as (
	select o.CustomerID,sum(od.UnitPrice) as Aggregated 
	from [Order Details] od 
	inner join Orders o on (o.OrderID=od.OrderID)
	group by o.CustomerID
),
t2 as (
	select avg(t1.Aggregated) as AvgPrice
	from t1
)
select * 
from t1
where (t1.Aggregated>any(select AvgPrice from t2));
-- 列出最熱銷的產品，以及被購買的總金額
with t1 as (
	select top 1 ProductID,sum(Quantity) as AggQuan
	from [Order Details] od
	group by ProductID
	order by AggQuan desc
),
t2 as (
	select *
	from [Order Details]
	where (ProductID=any(select ProductID from t1))
),
t3 as (
	select ProductID,UnitPrice*(1-Discount)*Quantity as Price 
	from t2
)
select ProductID,sum(Price) as Revenue 
from t3 group by ProductID;
-- 列出最少人買的產品
select top 1 ProductID,sum(Quantity) as AggQuan
from [Order Details] od
group by ProductID
order by AggQuan asc;
-- 列出最沒人要買的產品類別 (Categories)
with t1 as (
	select ProductID,sum(Quantity) as AggQuan
	from [Order Details]
	group by ProductID
)
select top 1 p.CategoryID , sum(AggQuan) as AggCate
from t1
inner join Products p on (p.ProductID=t1.ProductID)
group by CategoryID
order by AggCate;
-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)
with t1 as (
	select 
		od.ProductID,
		p.ProductName,
		p.SupplierID,
		od.UnitPrice*(1-od.Discount)*od.Quantity as AggPrice
	from [Order Details] od
	inner join Products p on (p.ProductID=od.ProductID)
),
t2 as (
	select SupplierID,sum(AggPrice) as SuppAggPrice
	from t1
	group by SupplierID
),
t3 as (
	select top 1 * from t2 order by SuppAggPrice desc
),
t4 as (
	select max(Quantity) as MaxQuan
	from [Order Details] od
	inner join Products p on (p.ProductID=od.ProductID)
	inner join Suppliers s on (s.SupplierID=p.SupplierID)
	where (s.SupplierID=any(select SupplierID from t3))
)
select c.CustomerID,c.ContactName,od.ProductID,p.SupplierID,od.UnitPrice*(1-Discount)*Quantity as Price
from Customers c
inner join Orders o on (o.CustomerID=c.CustomerID)
inner join [Order Details] od on (od.OrderID=o.OrderID)
inner join Products p on (p.ProductID=od.ProductID)
where (od.Quantity=any(select MaxQuan from t4) and p.SupplierID=any(select SupplierID from t3));
-- 列出那些產品沒有人買過
with t1 as (
	select p.ProductID
	from Products p
	inner join [Order Details] od on (od.ProductID=p.ProductID)
)
select p.ProductID,p.ProductName
from Products p
where (not exists(select * from t1 where (t1.ProductID=p.ProductID)));
-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額
with t1 as (
	select c.CustomerID , od.UnitPrice*(1-od.Discount)*od.Quantity as ConsumPrice 
	from Customers c
	inner join Orders o on (o.CustomerID=c.CustomerID)
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	where (Fax is null)
)
select CustomerID,sum(ConsumPrice)
from t1
group by CustomerID;
-- 列出每一個城市消費的產品種類數量
select p.ProductID,sum(od.Quantity) as SalesAmount
from [Order Details] od
inner join Products p on (p.ProductID=od.ProductID)
group by p.ProductID;
-- 列出目前沒有庫存的產品在過去總共被訂購的數量

-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過

-- 列出每位員工的下屬的業績總金額

-- 列出每家貨運公司運送最多的那一種產品類別與總數量
with SumOfEachProBySup as (
	select 
		s.SupplierID,
		p.ProductID,
		sum(od.Quantity) as Qty 
	from Suppliers s
	inner join Products p on (p.SupplierID=s.SupplierID)
	inner join [Order Details] od on (od.ProductID=p.ProductID)
	group by s.SupplierID,p.ProductID
),
MaxOfEachProBySup as (
	select SupplierID,max(Qty) as MaxQty
	from SumOfEachProBySup 
	group by SupplierID
)
select *
from SumOfEachProBySup ss
where (ss.Qty=any(select MaxQty from MaxOfEachProBySup where SupplierID=ss.SupplierID));
-- 列出每一個客戶買最多的產品類別與金額
with MostQrtByCust as (
	select 
		c.CustomerID,
		max(od.Quantity) as QtyPerCust
	from Customers c
	inner join Orders o on (o.CustomerID=c.CustomerID)
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	group by c.CustomerID
),
MostPurchaseByCust as (
	select o.CustomerID,p.CategoryID,od.Quantity*od.UnitPrice*(1-od.Discount)as Price
	from Orders o
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	inner join Products p on (p.ProductID=od.ProductID)
	where (
		o.CustomerID=any(select CustomerID from MostQrtByCust where CustomerID=o.CustomerID)
		and
		od.Quantity=any(select QtyPerCust from MostQrtByCust where CustomerID=o.CustomerID)
	)
)
select * from MostPurchaseByCust;
-- 列出每一個客戶買最多的那一個產品與購買數量
with MostQrtByCust as (
	select 
		c.CustomerID,
		max(od.Quantity) as QtyPerCust
	from Customers c
	inner join Orders o on (o.CustomerID=c.CustomerID)
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	group by c.CustomerID
),
MostPurchaseByCust as (
	select o.CustomerID,od.ProductID,p.ProductName,od.Quantity
	from Orders o
	inner join [Order Details] od on (od.OrderID=o.OrderID)
	inner join Products p on (p.ProductID=od.ProductID)
	where (
		o.CustomerID=any(select CustomerID from MostQrtByCust where CustomerID=o.CustomerID)
		and
		od.Quantity=any(select QtyPerCust from MostQrtByCust where CustomerID=o.CustomerID)
	)
)
select * from MostPurchaseByCust;
-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間
select c.City,max(o.ShippedDate) 
from Customers c
inner join Orders o on (o.CustomerID=c.CustomerID)
group by c.City;
-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距
with PriceOD as (
	select *,UnitPrice*Quantity*(1-Discount) as Price
	from [Order Details]
),
AggPricePerCust as (
	select o.CustomerID,sum(Price) as AggPrice
	from PriceOD od
	inner join Orders o on (o.OrderID=od.OrderID)
	group by o.CustomerID
),
Selection as (
	select row_number() over (order by AggPrice desc) as RowNum , * 
	from AggPricePerCust
),
Selection2 as (
	select max(AggPrice)-min(AggPrice) as Differences 
	from Selection
	where (RowNum in (5,10))
)
select *
from Selection ss
full join Selection2 sss on (sss.Differences>0)
where (ss.RowNum in (5,10))
