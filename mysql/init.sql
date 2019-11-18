drop schema if exists Payoneer;
Create Schema Payoneer;
Create Table Payoneer.Customers (Customer_ID int NOT NULL AUTO_INCREMENT,Customer_Status tinyint, Customer_Create_date datetime, PRIMARY KEY (Customer_ID));

ALTER TABLE Payoneer.Customers  AUTO_INCREMENT=4214532;
Create Table Payoneer.Accounts (Account_ID int NOT NULL AUTO_INCREMENT,Account_Status tinyint, Account_Currency varchar(6), Account_Current_Balance_Amount Decimal(10,2),Customer_ID int, Account_Create_date datetime, PRIMARY KEY(Account_id)) ;
ALTER TABLE Payoneer.Accounts  AUTO_INCREMENT=64323;

Create Table Payoneer.Charges (Charge_ID int NOT NULL AUTO_INCREMENT, Account_ID int,Charge_Currency varchar(6),Charge_status tinyint , Charge_Amount Decimal(10,2), Charge_date  datetime, Charge_Create_date  datetime, Primary Key(Charge_id)) ;
ALTER TABLE Payoneer.Charges  AUTO_INCREMENT=94142144;


drop procedure if exists Payoneer.insert_customers;
DELIMITER //
CREATE PROCEDURE Payoneer.insert_customers 
(
cnt int
)
BEGIN
    
select cnt;

WHILE cnt <= 1500 DO

insert into Payoneer.Customers (Customer_Create_date,Customer_Status)
select current_timestamp(),ROUND((RAND() * (5-1))+1);
 set cnt = cnt+1;

END WHILE;
END //

DELIMITER ;


 
call Payoneer.insert_customers(10);


insert into Payoneer.Accounts (Account_Status,Account_Currency,Account_Current_Balance_Amount,Customer_ID,Account_Create_date)
select ROUND((RAND() * (4-2))+2) as Account_Status, 'USD' as Account_Currency,cast(((RAND() * (46736-0))+0)as decimal(10,2)) as Account_Balance,Customer_ID,current_timestamp() from Payoneer.Customers;

select min(Account_ID) from Payoneer.Accounts ;

drop procedure if exists Payoneer.insert_charges;
DELIMITER //
CREATE PROCEDURE Payoneer.insert_charges
(
)
BEGIN
    
set @charge_cnt=(select min(Account_ID) from Payoneer.Accounts) ;

	WHILE @charge_cnt <= (select MAX(Account_ID) from Payoneer.Accounts) DO


	SET @trn_num = (select ROUND((RAND() * (5-1))+1));


	WHILE @trn_num >= 2 DO



	insert into Payoneer.Charges (Account_ID,Charge_Currency,Charge_status,Charge_Amount,Charge_Date,Charge_Create_Date)


	select @charge_cnt,'USD',ROUND((RAND() * (4-2))+2) as Charge_Status, cast(((RAND() * (2736-0))+0)as decimal(10,2)) as Charge_Amount,  DATE_ADD(current_timestamp(), INTERVAL ROUND((RAND() * (-25000-35))-35) HOUR) as Charge_Date,current_timestamp() as Charge_Create_date;
	select current_timestamp(),ROUND((RAND() * (5-1))+1);

	SET @trn_num= @trn_num-1;

END WHILE;



set @charge_cnt = @charge_cnt+1;

END WHILE;
END //

DELIMITER ;

call Payoneer.insert_charges;

select * from Payoneer.Charges



