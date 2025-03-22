-- Title: SQL Project – Film Data Analysis
-- Description:
-- This project analyzes a film rental dataset to generate insights into costs, performance, and customer behavior.
-- It involves tasks such as grouping, aggregation, filtering, and joins to extract meaningful insights from the data.

-- Task 1: Find the lowest replacement cost of films
SELECT DISTINCT MIN(replacement_cost) AS lowest_replacement_cost
FROM film;

-- Task 2: Group films into categories based on replacement cost
SELECT 
    CASE
        WHEN replacement_cost <= 19.99 THEN 'LOW'
        WHEN replacement_cost BETWEEN 20.00 AND 24.99 THEN 'MEDIUM'
        ELSE 'HIGH'
    END AS price_category,
    COUNT(*) AS total_count
FROM film
GROUP BY 
    CASE
        WHEN replacement_cost <= 19.99 THEN 'LOW'
        WHEN replacement_cost BETWEEN 20.00 AND 24.99 THEN 'MEDIUM'
        ELSE 'HIGH'
    END;

-- Task 3:List film titles, length, and category name for 'Drama' or 'Sports' (ordered by length)
SELECT 
    f.title, 
    f.length, 
    c.name 
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Sports')
ORDER BY f.length DESC;

-- Task 4: Count films by category
SELECT 
    c.name, 
    COUNT(f.title) AS total_count
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY total_count DESC;

-- Task 5:List actors and number of films they appear in
SELECT 
    a.actor_id, 
    a.first_name, 
    a.last_name, 
    COUNT(fa.film_id) AS film_counts_of_actors
FROM actor a
LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY film_counts_of_actors DESC;

-- Task 6: List addresses not associated with any customer
SELECT *
FROM address a
LEFT JOIN customer c ON a.address_id = c.address_id
WHERE c.first_name IS NULL;

-- Task 7: Find the city with the highest sales amount
SELECT 
    ci.city, 
    SUM(p.amount) AS total_sales
FROM payment p
INNER JOIN customer c ON p.customer_id = c.customer_id
INNER JOIN address a ON c.address_id = a.address_id
INNER JOIN city ci ON a.city_id = ci.city_id
GROUP BY ci.city
ORDER BY total_sales DESC;

-- Task 8: Find least sales by country and city
SELECT
    CONCAT(co.country, ', ', ci.city) AS location,
    SUM(p.amount) AS total_sales
FROM payment p
LEFT JOIN customer c ON p.customer_id = c.customer_id
LEFT JOIN address a ON c.address_id = a.address_id
LEFT JOIN city ci ON a.city_id = ci.city_id
LEFT JOIN country co ON ci.country_id = co.country_id
GROUP BY location
ORDER BY total_sales ASC;

-- Task 9: Average sales amount per staff_id per customer
SELECT 
    staff_id, 
    ROUND(AVG(total), 2) AS avg_revenue_per_customer
FROM (
    SELECT 
        staff_id, 
        customer_id, 
        SUM(amount) AS total
    FROM payment
    GROUP BY staff_id, customer_id
) sub
GROUP BY staff_id;

-- Task 10: Average daily revenue on Sundays
SELECT 
    AVG(total_amount) AS avg_revenue
FROM (
    SELECT 
        SUM(amount) AS total_amount,
        DATE(payment_date) AS payment_date,
        EXTRACT(DOW FROM payment_date) AS payment_day
    FROM payment
    WHERE EXTRACT(DOW FROM payment_date) = 0
    GROUP BY DATE(payment_date), payment_day
) daily;

-- Task 11: List films longer than average length per replacement cost group
SELECT 
    f1.title, 
    f1.length, 
    f1.replacement_cost
FROM film f1
WHERE f1.length > (
    SELECT AVG(f2.length)
    FROM film f2
    WHERE f1.replacement_cost = f2.replacement_cost
)
ORDER BY f1.length ASC;

-- Task 12:Average customer lifetime value by district
SELECT 
    ROUND(AVG(total_amount), 2) AS avg_lifetime_value, 
    district
FROM (
    SELECT 
        c.customer_id, 
        SUM(p.amount) AS total_amount, 
        a.district
    FROM payment p
    INNER JOIN customer c ON p.customer_id = c.customer_id
    INNER JOIN address a ON c.address_id = a.address_id
    GROUP BY c.customer_id, a.district
) sub
GROUP BY district
ORDER BY avg_lifetime_value DESC;

-- Task 13: Payments by category and total revenue in that category
SELECT 
    p.amount, 
    p.payment_id, 
    c1.name,
    (SELECT SUM(amount)
     FROM payment
     LEFT JOIN rental r ON p.rental_id = r.rental_id
     LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
     LEFT JOIN film_category fc ON i.film_id = fc.film_id
     LEFT JOIN category c ON fc.category_id = c.category_id
     WHERE c.name = c1.name) AS total_amount
FROM payment p
LEFT JOIN rental r ON p.rental_id = r.rental_id
LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
LEFT JOIN film_category fc ON i.film_id = fc.film_id
LEFT JOIN category c1 ON c1.category_id = fc.category_id
ORDER BY c1.name, p.payment_id ASC;

-- Task 14: Top-performing film in each category
SELECT
    f.title,
    c.name,
    SUM(p.amount) AS total_revenue
FROM payment p
LEFT JOIN rental r ON r.rental_id = p.rental_id
LEFT JOIN inventory i ON i.inventory_id = r.inventory_id
LEFT JOIN film f ON f.film_id = i.film_id
LEFT JOIN film_category fc ON fc.film_id = f.film_id
LEFT JOIN category c ON c.category_id = fc.category_id
GROUP BY c.name, f.title
HAVING SUM(p.amount) = (
    SELECT MAX(total)
    FROM (
        SELECT
            c1.name,
            f1.title,
            SUM(p1.amount) AS total
        FROM payment p1
        LEFT JOIN rental r1 ON r1.rental_id = p1.rental_id
        LEFT JOIN inventory i1 ON i1.inventory_id = r1.inventory_id
        LEFT JOIN film f1 ON f1.film_id = i1.film_id
        LEFT JOIN film_category fc1 ON fc1.film_id = f1.film_id
        LEFT JOIN category c1 ON c1.category_id = fc1.category_id
        GROUP BY c1.name, f1.title
    ) sub
    WHERE c.name = sub.name
);



