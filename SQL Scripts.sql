/*Q-1
Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/

SELECT DISTINCT market
FROM dim_customer
WHERE region='APAC' AND customer='Atliq Exclusive';

/*Q-2
What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg*/


WITH Fy_sales AS 
(SELECT COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN product_code END) AS unique_products_2020,
COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN product_code END) AS unique_products_2021
FROM fact_sales_monthly)

SELECT unique_products_2020,unique_products_2021,
CONCAT(ROUND((unique_products_2021-unique_products_2020)/(unique_products_2020) * 100, 2), '%') AS percentage_chg
FROM Fy_sales;

/*Q-3

Provide a report with all the unique product counts for each segment and sort them in descending order 
of product counts. The final output contains 2 fields, segment & product_count*/


SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


/*Q-4

Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
The final output contains these fields, segment, product_count_2020, product_count_2021, difference*/
 
WITH Fy_sales AS 
(SELECT d.segment, COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN fs.product_code END) AS unique_products_2020,
COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN fs.product_code END) AS unique_products_2021
FROM dim_product AS d INNER JOIN fact_sales_monthly AS fs
ON d.product_code=fs.product_code
GROUP BY d.segment)

SELECT segment,unique_products_2020 AS product_count_2020,unique_products_2021 AS product_count_2021,
(unique_products_2021-unique_products_2020) AS  difference
FROM Fy_sales;

/*Q-5

Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields, product_code, product, manufacturing_cost*/


SELECT m.product_code, p.product, m.manufacturing_cost
FROM fact_manufacturing_cost AS m
INNER JOIN dim_product AS p ON m.product_code = p.product_code
WHERE m.manufacturing_cost IN
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY m.manufacturing_cost DESC;


/*Q-6
Generate a report which contains the top 5 customers who received an average 
high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
The final output contains these fields, customer_code, customer, average_discount_percentage */
 
WITH avg_discount_pct AS(SELECT c.customer_code,c.customer,
AVG(pi.pre_invoice_discount_pct) AS average_discount_pct,
CONCAT(ROUND(AVG(pi.pre_invoice_discount_pct) * 100, 2), ' ', '%') AS average_discount_with_percentage_sign
FROM dim_customer AS c
INNER JOIN fact_pre_invoice_deductions AS pi ON c.customer_code = pi.customer_code
WHERE pi.fiscal_year = 2021 AND c.market = 'India'
GROUP BY c.customer_code, customer)

SELECT customer_code,customer,average_discount_with_percentage_sign
FROM avg_discount_pct
ORDER BY average_discount_pct DESC
LIMIT 5;


/*Q-7
Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
This analysis helps to get an idea of low and high-performing months and take strategic decisions.
The final report contains these columns: Month, Year, Gross sales Amount */

SELECT MONTHNAME(fs.date) AS Month,YEAR(fs.date) AS Year,
CONCAT(ROUND(SUM(fs.sold_quantity * fg.gross_price)/1000000, 2), '$') AS Gross_sales_amount
FROM fact_sales_monthly AS fs
INNER JOIN fact_gross_price AS fg ON fs.product_code = fg.product_code
AND fg.fiscal_year=fs.fiscal_year
INNER JOIN dim_customer AS c ON c.customer_code = fs.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY Month, Year
ORDER BY Gross_sales_amount DESC;


/*Q-8
In which quarter of 2020, got the maximum total_sold_quantity?
The final output contains these fields sorted by the total_sold_quantity,
Quarter, total_sold_quantity */

SELECT CASE 
WHEN MONTH(date) IN (9,10,11) THEN "Q1" 
WHEN MONTH(date) IN (12,1,2) THEN "Q2"
WHEN MONTH(date) IN (3,4,5) THEN "Q3"
ELSE "Q4"  END AS Quarter,
SUM(sold_quantity) AS total_quantity_sold
FROM fact_sales_monthly
WHERE fiscal_year = '2020'
GROUP BY Quarter
ORDER BY  total_quantity_sold DESC;


/*Q-9
Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields, channel, gross_sales_mln, percentage */


WITH gross_sales_by_channel AS (SELECT
c.channel AS Channel,
SUM(fs.sold_quantity * fg.gross_price) AS Gross_sales_amount
FROM fact_sales_monthly AS fs
INNER JOIN fact_gross_price AS fg ON fs.product_code = fg.product_code
INNER JOIN dim_customer AS c ON c.customer_code = fs.customer_code
WHERE fs.fiscal_year = 2021
GROUP BY Channel)

SELECT Channel,
CONCAT(ROUND(Gross_sales_amount / 1000000, 2), ' ', 'M') AS gross_sales_mln,
CONCAT(ROUND(Gross_sales_amount / (SELECT SUM(Gross_sales_amount) FROM gross_sales_by_channel) * 100, 2), ' %') AS percentage
FROM gross_sales_by_channel
ORDER BY percentage DESC;


/*Q-10

Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
The final output contains these fields, division, product_code */
 
 
WITH division_and_pcode AS(SELECT P.division AS division,fs.product_code,p.product AS product,SUM(fs.sold_quantity) AS Total_Qty_sold
FROM dim_product AS p
INNER JOIN fact_sales_monthly AS fs ON p.product_code = fs.product_code
WHERE fs.fiscal_year = 2021
GROUP BY division,fs.product_code,p.product),

Ranked_products AS(SELECT *,DENSE_RANK()OVER(PARTITION BY division ORDER BY Total_Qty_sold DESC) AS RnK
FROM division_and_pcode)

SELECT *
FROM Ranked_products
WHERE RnK <=3


