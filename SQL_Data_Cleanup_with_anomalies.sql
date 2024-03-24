use assignment
select * from load


//******Step 1:Data Cleaning*******//

Removing NULL values

Update load set [First Name]='' where [First Name] is null
Update load set [Middle Name]='' where [Middle Name] is null
Update load set [last Name]='' where [Last Name] is null

Removing char(160) values

Update load set [First Name]=replace([First Name],char(160),'')
Update load set [Middle Name]=replace([Middle Name],char(160),'')
Update load set [last Name]=replace([last Name],char(160),'')

Removing char(10) values

Update load set [First Name]=replace([First Name],char(10),'')
Update load set [Middle Name]=replace([Middle Name],char(10),'')
Update load set [last Name]=replace([last Name],char(10),'')

Removing unnecessary spaces


SELECT SOUNDEX('Smith'), SOUNDEX('Smyth')

Update load set [First Name]=trim([First Name])
Update load set [Middle Name]=trim([Middle Name])
Update load set [Last Name]=trim([Last Name])



//************Step 2: Discovering Data Anomalies*******//


//**********1) One SSN Multiple Names removing all the SSNs with multiple references with one Name as 'Unknown'**********//


select distinct l1.SSN,l1.[First Name],l1.[Last Name] from load as l1
join
load as l2
on l1.SSN=l2.SSN
and l1.SSN<>''
and l2.SSN<>''
and (l1.[First Name]<>l2.[First Name] or l1.[Last Name]<>l2.[Last Name])
and l1.[First Name]<>'Unknown'
and l2.[First Name]<>'Unknown'
and l1.[Last Name]<>'Unknown'
and l2.[Last Name]<>'Unknown'
order by l1.SSN


//********2) One DOB Multiple names excluding instances of same DOB with Names Unknown************//


select distinct l1.DOB,l1.[First Name],l1.[Last Name] from load as l1
join
load as l2
on l1.DOB=l2.DOB
and l1.DOB<>''
and l2.DOB<>''
and (l1.[First Name]<>l2.[First Name] or l1.[Last Name]<>l2.[Last Name])
and l1.[First Name]<>'Unknown'
and l2.[First Name]<>'Unknown'
and l1.[Last Name]<>'Unknown'
and l2.[Last Name]<>'Unknown'
order by l1.DOB


//**********3) 1 SSN Multiple DOB************//


select distinct l1.SSN,l1.DOB
from load as l1
join load as l2 
on l1.SSN=l2.SSN
and l1.DOB<>l2.DOB
and l1.SSN<>''
and l2.SSN<>''
and l1.DOB<>''
and l2.DOB<>''



//*********4) 1 Name Multiple SSN**************//

alter table load add [Full Name] varchar(200)
update load set [Full Name]=CONCAT([First name],'',[Last name])


select distinct l1.[Full Name],l1.SSN
from load as l1
join
load as l2
on l1.[Full Name]=l2.[Full Name]
and l1.SSN<>l2.SSN
and l1.SSN<>''
and l2.SSN<>''
and l1.[First name]<>'Unknown'
and l1.[Last name]<>'Unknown'
and l2.[First name]<>'Unknown'
and l2.[Last name]<>'Unknown'
order by [Full Name]


//****5) Finding reverse name scenarios in the dataset( keeping unique occurrence of each pair)*****//

select distinct l1.[First name],l1.[last name]
from load as l1
join
load as l2
on (l1.[First name]=l2.[last name] and l1.[Last name]=l2.[First name])
and (l1.[First name]<>l2.[First name] and l1.[last name]<>l2.[Last name])
and l1.[First name]<l1.[Last name]



//********6)Names with same firstname and similar(but not exactly the same) lastnames*****//

select distinct ss.[PII - First Name],ss.[PII - Last Name],sd.[PII - First Name],sd.[PII - Last Name]
from load as ss, load as sd
where ss.[PII - First Name]=sd.[PII - First Name] 
and
SOUNDEX(ss.[PII - Last Name])=SOUNDEX(sd.[PII - Last Name])
and
ss.[PII - Last Name]<>sd.[PII - Last Name]
and
ss.[PII - Last Name]<>''
order by ss.[PII - First Name],ss.[PII - Last Name]

//****7)same nUmber captured both as Patient Account NUmber and Medical Record NUmber******//

select distinct ss.[PII - Patient Account Number],sd.[PII - Medical Record Number]
from load as ss, load as sd
where ss.[PII - Patient Account Number]=sd.[PII - Medical Record Number]
and (ss.[PII - Patient Account Number]<>sd.[PII - Patient Account Number] or ss.[PII - Patient Account Number]<>sd.[PII - Patient Account Number])
and ss.[PII - Patient Account Number]<>''
and ss.[PII - Medical Record Number]<>''
and sd.[PII - Patient Account Number]<>''
and sd.[PII - Patient Account Number]<>''

update load set [PII - Medical Record Number]='15127011' where [PII - Medical Record Number]='1580389720'




------8)Detect Names and addresses with special characters(other than alphabets)


SELECT distinct Address1
FROM load
WHERE Address1 LIKE '%[^A-Za-z ]%' COLLATE Latin1_General_BIN;

SELECT distinct [Full Name]
FROM load
WHERE [Full Name] LIKE '%[^A-Za-z ]%' COLLATE Latin1_General_BIN;


--------9)Format the Names with 'Mckinzey' as 'McKinzey' in the dataset

Update load set [PII - First Name]=
(select case
When left([PII - First Name],2)='Mc' then concat('Mc',upper(substring([PII - First Name],3,1)),right([PII - First Name],len([PII - First Name])-3))
Else [PII - First Name]
End as [PII - First Name]
);

---------10) Format the Names with 'Macdonalds' as 'MacDonalds'


//***Before making the changes, we are creating a new column and copy the original values in that column, and make hanges in this column***//

alter table load add first_b varchar(600)
update load set first_b = [PII - First Name]

Update load set [PII - First Name]=
(select case
When left([PII - First Name],3)='Mac' then concat('Mac',upper(substring([PII - First Name],4,1)),right([PII - First Name],len([PII - First Name])-4))
Else [PII - First Name]
End as [PII - First Name]
);




----11) How to do a proper case of Names and Address columns

create function ProperCase(@Text as varchar(8000))
returns varchar(8000)
as
begin
  declare @Reset bit;
  declare @Ret varchar(8000);
  declare @i int;
  declare @c char(1);

  if @Text is null
    return null;

  select @Reset = 1, @i = 1, @Ret = '';

  while (@i <= len(@Text))
    select @c = substring(@Text, @i, 1),
      @Ret = @Ret + case when @Reset = 1 then UPPER(@c) else LOWER(@c) end,
      @Reset = case when @c like '[a-zA-Z]' then 0 else 1 end,
      @i = @i + 1
  return @Ret
end



Update load set [PII - First Name]=dbo.propercase([PII - First Name])
Update load set [PII - Middle Name]=dbo.propercase([PII - Middle Name])
Update load set [PII - Last Name]=dbo.propercase([PII - Last Name])

Update load set Address1=dbo.propercase(Address1)