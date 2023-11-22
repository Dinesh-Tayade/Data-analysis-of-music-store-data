

/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */
    select * from employee
    order by levels desc
    limit 1;
    
/* Q2: Which countries have the most Invoices? */
    select billing_country,count(*) as count_of_invoices from invoice 
    group by billing_country
    order by count_of_invoices desc;
    
 /* Q3: What are top 3 values of total invoice? */
	 select * from invoice 
     order by total desc
     limit 3;
  
  /* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
     Write a query that returns one city that has the highest sum of invoice totals. 
     Return both the city name & sum of all invoice totals */
     
     select billing_city ,sum(total) as sum_of_invoice_total
     from invoice
     group by billing_city
     order by sum_of_invoice_total desc
     limit 1;
     
 /* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
	Write a query that returns the person who has spent the most money.*/    
     
	select c.customer_id,c.first_name,c.last_name,sum(i.total) as total_spent_money
    from customer c inner join invoice i
    on c.customer_id=i.customer_id
    group by c.customer_id,c.first_name,c.last_name
    order by total_spent_money desc
    limit 1;
     
/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
   Return your list ordered alphabetically by email starting with A. */

-- solution 1=>

SELECT distinct email as  Email,first_name AS FirstName, last_name AS LastName,
(select name from  genre where name='Rock') AS genreName
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
ORDER BY email;   
  
-- solution 2 =>

select distinct email as email ,first_name,last_name
from customer join invoice 
on customer.customer_id=invoice.customer_id
join invoice_line 
on invoice_line.invoice_id=invoice.invoice_id
where track_id in (
                   select track_id from track 
                   join genre 
                   on track.genre_id=genre.genre_id
                   where genre.name = 'Rock'
                   )
order by email;
     
 /* Q2: Let's invite the artists who have written the most rock music in our dataset. 
    Write a query that returns the Artist name and total track count of the top 10 rock bands. */
    
	select a.artist_id,a.name,count(a.artist_id) as number_of_songs,g.name
    from artist a 
    join album2 al on a.artist_id=al.artist_id
    join track t on t.album_id=al.album_id
    join genre g on g.genre_id=t.genre_id
    where g.name like 'Rock'
    group by a.artist_id, a.name,g.name
    order by number_of_songs desc
    limit 10;
    
/* Q3: Return all the track names that have a song length longer than the average song length. 
   Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name,milliseconds, (select avg(milliseconds) 
                           from track)  as avg_length_track
from track 
where milliseconds >  (select avg(milliseconds) 
                      from track) 
order by milliseconds desc;


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as (
         select a.artist_id,a.name,
         sum(il.unit_price*il.quantity) as total_spent
         from invoice_line il
         join track t on il.track_id=t.track_id
         join album2 al on t.album_id=al.album_id
         join artist a on al.artist_id=a.artist_id
         group by 1 ,2
		 order by 3 desc
         limit 1
         )
select c.customer_id,concat(c.first_name,' ',c.last_name) as customer_name,
bsa.name as artist_name,sum(il.unit_price*il.quantity) as total_spent
from customer c
join invoice i on c.customer_id=i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id
join album2 al on al.album_id=t.album_id
join best_selling_artist as bsa on bsa.artist_id=al.artist_id
group by 1,2,3
order by 4 desc;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name as genre_name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/* Method 2: Using Subquery */

select tmp.* 
from 
(select count(il.quantity) as highest_purchases,c.country,g.name as genre_name,g.genre_id,
row_number() over(partition by country order by  count(il.quantity) desc) row_num
from customer c
join invoice i on c.customer_id=i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id
group by 2,3,4
order by 2 ,1 desc) as tmp
where row_num=1;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

with customer_with_country as (
select sum(total) as tota_spent,c.country,c.customer_id,concat(c.first_name,' ',c.last_name) as customer_name,
row_number() over(partition by country order by  sum(total) desc ) row_num
from customer c
join invoice i on  c.customer_id=i.customer_id
group by 2,3,4
order by 1 desc,2)
select * from customer_with_country  where row_num=1;


/* Method 2: using Subquery */

select tmp.*
from 
(select sum(total) as tota_spent,c.country,c.customer_id,concat(c.first_name,' ',c.last_name) as customer_name,
row_number() over(partition by country order by  sum(total) desc ) row_num
from customer c
join invoice i on  c.customer_id=i.customer_id
group by 2,3,4
order by 1 desc,2) as tmp
where row_num=1;


