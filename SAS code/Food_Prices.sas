*/ create a permanent library;
Libname food "/home/u64443627/Food";
run;

*/ import the raw datset into sas  for cleaning;
proc import datafile= "/home/u64443627/Food/Food_Prices.csv"
	dbms = csv 
	out =food.food_prices_raw
	replace;
	guessingrows=max;
run;

*/ use the contents procdure to inspect imported data;
proc contents data=food.food_prices_raw;
run;

*/Rename Columns/standardize columns for use in SAS;
data food.food_prices_clean;
    set food.food_prices_raw;

    rename 
        'Food Item'n = Food_item
       	'Unit of Measurement'n = Unit_of_Measurement
       	'Average Price'n = Average_Price
       	'Price in USD'n = Price_in_USD
        ;
run;

proc format;
    value monthfmt
        1 = "January"
        2 = "February"
        3 = "March"
        4 = "April"
        5 = "May"
        6 = "June"
        7 = "July"
        8 = "August"
        9 = "September"
        10 = "October"
        11 = "November"
        12 = "December";
run;

*/add month name;
data food.food_prices_clean;
    set food.food_prices_clean;
    Month_N= put(Month, monthfmt.); 
run;

*/ convert price in USD format NB;
data food.food_prices_clean;
	set food.food_prices_clean;
	format Price_in_USD  dollar12.2;
run;

*/check for missing values;
proc means data=food.food_prices_clean n nmiss;
run;


*/handle duplicates;
proc sort data=food.food_prices_clean nodupkey
          out=food.food_prices_sorted;
    by country year Food_item;
run;

*/ handle Average price outliers;
proc univariate data=food.food_prices_clean noprint;
    var Average_Price;
    output out=price_stats q1=Q1 q3=Q3;
run;

data food.food_prices_no_outliers;
    if _n_=1 then set price_stats;
    set food.food_prices_clean;

    IQR = Q3 - Q1;
    upper = Q3 + 1.5*IQR;
    lower = Q1 - 1.5*IQR;

    if Average_Price < lower then delete;
    if Average_Price > upper then delete;
    
drop  IQR;
drop  upper;
drop  lower; 
drop  Q1;  
drop  Q3; 
run;

*/ handle price in USD outliers;
proc univariate data=food.food_prices_clean noprint;
    var Price_in_USD;
    output out=price_stats q1=Q1 q3=Q3;
run;

data food.food_prices_no_outliers2;
    if _n_=1 then set price_stats;
    set food.food_prices_clean;

    IQR = Q3 - Q1;
    upper = Q3 + 1.5*IQR;
    lower = Q1 - 1.5*IQR;

    if Price_in_USD < lower then delete;
    if Price_in_USD > upper then delete;
    
drop  IQR;
drop  upper;
drop  lower; 
drop  Q1;  
drop  Q3;    
run;

*/seperate the data by year;
*/2018;
data food.food_prices_year_2018;
	set food.food_prices_clean;
	where year = 2018;
run;

*/2019;
data food.food_prices_year_2019;
	set food.food_prices_clean;
	where year = 2019;
run;

*/2020;
data food.food_prices_year_2020;
	set food.food_prices_clean;
	where year = 2020;
run;

*/2021;
data food.food_prices_year_2021;
	set food.food_prices_clean;
	where year = 2021;
run;

*/2022;
data food.food_prices_year_2022;
	set food.food_prices_clean;
	where year = 2022;
run;

*/ extract the countries;
proc sql;
    create table food.unique_countries as
    select distinct Country
    from food.food_prices_clean
    order by Country;
quit;

*/extract year;
proc sql;
    create table food.Year_ as
    select distinct Year
    from food.food_prices_clean
    order by Year;
quit;

*/ export reports;
*/ generate reports ;
ods excel file="/home/u64443627/Food/Food_Prices_Dataset.csv"
    options(
        sheet_interval="proc"   /* auto-sheet creation */
        embedded_titles="yes"   /* ensures titles appear in Excel */
        frozen_headers="yes"     /* freezes header row */
    );


ods excel options(sheet_name="Food Prices dataset");
*/ final dataset sheet;
proc print data=food.food_prices_clean label noobs;   
run;

ods excel options(sheet_name="Countries");
proc print data=food.unique_countries label noobs;
run;

ods excel options(sheet_name="Year");
proc print data=food.Year_ label noobs;
run;

/* Close the Excel workbook */
ods excel close;