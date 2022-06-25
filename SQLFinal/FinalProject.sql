create table Categories (
CategoryID int identity(1,1) primary key,
CategoryName varchar(50) not null,
ProductLine varchar(15) 
);


insert into Categories (CategoryName)
select Category
from Product
group by Category;

update Categories
set ProductLine = 'Accessories'
where CategoryName = 'Locks' 
		or CategoryName = 'Cleaners' 
		or CategoryName = 'Helmets'
		or CategoryName = 'Bottles and Cages'
		or CategoryName = 'Hydration Packs'
		or CategoryName = 'Fenders'
		or CategoryName = 'Pumps'
		or CategoryName = 'Bike Stands'
		or CategoryName = 'Bike Racks'
		or CategoryName = 'Lights'
		or CategoryName = 'Panniers'

update Categories
set ProductLine = 'Components'
where CategoryName = 'Road Frames' 
		or CategoryName = 'Mountain Frames' 
		or CategoryName = 'Deraileurs'
		or CategoryName = 'Brakes'
		or CategoryName = 'Forks'
		or CategoryName = 'Touring Frames'
		or CategoryName = 'Chains'
		or CategoryName = 'Handlebars'
		or CategoryName = 'Saddles'
		or CategoryName = 'Pedals'
		or CategoryName = 'Headsets'
		or CategoryName = 'Cranksets'
		or CategoryName = 'Bottom Brackets'

update Categories
set ProductLine = 'Bikes'
where CategoryName = 'Road Bikes'
		or CategoryName = 'Mountain Bikes'
		or CategoryName = 'Touring Bikes'

update Categories
set ProductLine = 'Clothing'
where ProductLine is null

alter table Product
add CategoryID int;

update Product
set CategoryID = (select CategoryID from Categories c where c.CategoryName = Category);

alter table Product
drop column Category;

create table Addresses (
AddressID int identity(1,1),
CustomerID int not null,
AddressType char(4) not null,
Address varchar(50) not null,
City varchar(30) not null,
State char(2) not null,
ZipCode varchar(10) not null,
primary key (AddressID),
foreign key (CustomerID) references Customer(CustomerID)
);

insert into Addresses(CustomerID,AddressType, Address,City, State, ZipCode)
select CustomerID, 'Home', Address, City, State, ZipCode from Customer;

insert into Addresses(CustomerID,AddressType, Address, City, State, ZipCode)
select distinct h.CustomerID, 'Ship', h.ShipAddress, h.ShipCity, h.ShipState, h.ShipZipCode 
from OrderHeader h
join Customer c on c.CustomerID = h.CustomerID
order by CustomerID;

alter table Customer
add AddressID int;

alter table OrderHeader
add AddressID int;

update Customer
set AddressID = (select AddressID from Addresses a where a.CustomerID = Customer.CustomerID and AddressType='Home');

update OrderHeader
set AddressID = (select AddressID from Addresses a where a.CustomerID = OrderHeader.CustomerID and a.AddressType='Ship');

alter table Customer
drop column Address,City,State,ZipCode;

alter table OrderHeader
drop column ShipAddress,ShipCity,ShipState,ShipZipCode;

alter table OrderDetail
add constraint fk_OrderID 
foreign key (OrderID) references OrderHeader(OrderID);

alter table OrderDetail
add constraint fk_ProductID 
foreign key (ProductID) references Product(ProductID);

alter table OrderDetail
alter column SalesPromotionID smallint;

alter table OrderDetail
add constraint fk_SalesPromotionID 
foreign key (SalesPromotionID) references SalesPromotion(SalesPromotionID);

alter table Product
add constraint fk_VendorID
foreign key (VendorID) references Vendor(VendorID);

alter table Product
add constraint fk_CategoryID
foreign key (CategoryID) references Categories(CategoryID);

alter table OrderHeader
add constraint fk_CustomerID 
foreign key (CustomerID) references Customer(CustomerID);

alter table OrderHeader
add constraint fk_Order_AddressID
foreign key (AddressID) references Addresses(AddressID);

alter table Customer
add constraint fk_AddressID
foreign key (AddressID) references Addresses(AddressID);

insert into SalesTax
select distinct State,0,State+' State Sales Tax' from Addresses where State not in('FL','AZ','WA','TX','MA','UT','MN','CA')

alter table SalesTax
drop constraint pk_SalesTax

alter table SalesTax
drop column SalesTaxID

alter table SalesTax
add constraint pk_SalesTax
primary key (State)

alter table Addresses
add constraint fk_State
foreign key (State) references SalesTax(State)

alter table Addresses
add constraint fk_Address_CustomerID
foreign key (CustomerID) references Customer(CustomerID)

go
create procedure CustomerHomeAddress(@CustomerID int) as
select c.FirstName + ' ' + c.LastName as "CustomerName", a.Address + ' ' + a.City + ' ' + a.State + ' ' +a.ZipCode as "Home Address"
from Customer c
join Addresses a on a.CustomerID = c.CustomerID
where a.AddressType = 'Home' and c.CustomerID = @CustomerID
go
exec CustomerHomeAddress @CustomerID = 170;

go
create function CalculateSalesTax
(@State char(2), @Amount money)
returns money
as
	begin
	declare @TotalTax money
		if(@State in(select State from SalesTax))
			begin
				select @TotalTax = @amount*(TaxRate/100) from SalesTax where State = @State
			end
		else
			begin
			set @TotalTax = 0
			end
	return @TotalTax
	end
go

go
create view CustomerOrderCost 
as
select c.FirstName + ' ' + c.LastName as "Name", 
	   format(sum(d.OrderQuantity*p.ListPrice*(1-s.DiscountPercent)),'c') as "SubTotal", 
	   format(sum(d.OrderQuantity*p.ListPrice*(1-s.DiscountPercent))*(t.TaxRate/100),'c') as "Tax",
	   format(h.ShippingCost,'c') as "Freight",
	   format(sum(d.OrderQuantity*p.ListPrice*(1-s.DiscountPercent)) 
	   + sum(d.OrderQuantity*p.ListPrice*(1-s.DiscountPercent))*(t.TaxRate/100)
	   + h.ShippingCost,'c') as "OrderTotal",
	   a.Address + ' ' + a.City + ' ' + a.State + ' ' + a.ZipCode as "ShipAddress",
	   (select Address + ' ' + City + ' ' + State + ' ' + ZipCode from Addresses where CustomerID = c.CustomerID and AddressType = 'Home') as "HomeAddress"
from Customer c
join OrderHeader h on h.CustomerID = c.CustomerID
join OrderDetail d on d.OrderID = h.OrderID
join Product p on p.ProductID = d.ProductID
join SalesPromotion s on s.SalesPromotionID = d.SalesPromotionID
join Addresses a on h.AddressID = a.AddressID
join SalesTax t on t.State = a.State
where h.OrderID = 958
group by c.FirstName,c.LastName, h.ShippingCost, t.TaxRate, a.Address, a.City, a.State, a.ZipCode, c.CustomerID
go













