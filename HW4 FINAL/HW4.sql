-- ////////////////////////////////////////// Adding primary keys
ALTER TABLE actor ADD PRIMARY KEY (actor_id);
ALTER TABLE address ADD PRIMARY KEY (address_id);
ALTER TABLE category ADD PRIMARY KEY (category_id);
ALTER TABLE city ADD PRIMARY KEY (city_id);
ALTER TABLE country ADD PRIMARY KEY (country_id);
ALTER TABLE customer ADD PRIMARY KEY (customer_id);
ALTER TABLE film ADD PRIMARY KEY (film_id);
ALTER TABLE inventory ADD PRIMARY KEY (inventory_id);
ALTER TABLE language ADD PRIMARY KEY (language_id);
ALTER TABLE payment ADD PRIMARY KEY (payment_id);
ALTER TABLE rental ADD PRIMARY KEY (rental_id);
ALTER TABLE staff ADD PRIMARY KEY (staff_id);
ALTER TABLE store ADD PRIMARY KEY (store_id);

-- composite keys for film_actor and category
ALTER TABLE film_actor ADD PRIMARY KEY (actor_id, film_id);
ALTER TABLE film_category ADD PRIMARY KEY (film_id, category_id);

-- Foriegn and Primary Keys for adress city customer film inventory payment rental staff and film actor aand category
-- address Foreign Keys
ALTER TABLE address ADD CONSTRAINT fk_address2city FOREIGN KEY (city_id) REFERENCES city(city_id);

-- City Foreign Keys
ALTER TABLE city ADD CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES country(country_id);

-- Customer Foreign Keys
ALTER TABLE customer
    ADD CONSTRAINT fk_customer2address FOREIGN KEY (address_id) REFERENCES address(address_id),
    ADD CONSTRAINT fk_customer2store FOREIGN KEY (store_id) REFERENCES store(store_id);

-- Film Foreign Keys
ALTER TABLE film ADD CONSTRAINT fk_film2lang FOREIGN KEY (language_id) REFERENCES language(language_id);

-- Inventory Foreign Keys
ALTER TABLE inventory
    ADD CONSTRAINT fk_inventory2film FOREIGN KEY (film_id) REFERENCES film(film_id),
    ADD CONSTRAINT fk_inventory2store FOREIGN KEY (store_id) REFERENCES store(store_id);

-- Payment Foreign Keys
ALTER TABLE payment
    ADD CONSTRAINT fk_payment2customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    ADD CONSTRAINT fk_payment2staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    ADD CONSTRAINT fk_payment2rental FOREIGN KEY (rental_id) REFERENCES rental(rental_id);

-- Rental Foreign Keys
ALTER TABLE rental
    ADD CONSTRAINT fk_rental2inventory FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id),
    ADD CONSTRAINT fk_rental2customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    ADD CONSTRAINT fk_rental2staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id);

-- staff Foreign Keys
ALTER TABLE staff
    ADD CONSTRAINT fk_staff2address FOREIGN KEY (address_id) REFERENCES address(address_id),
    ADD CONSTRAINT fk_staff2store FOREIGN KEY (store_id) REFERENCES store(store_id);

-- film_actor Foreign Keys
ALTER TABLE film_actor
    ADD CONSTRAINT fk_filmact2film FOREIGN KEY (film_id) REFERENCES film(film_id),
    ADD CONSTRAINT fk_filmact2actor FOREIGN KEY (actor_id) REFERENCES actor(actor_id);
    
-- film_category Foreign Keys
ALTER TABLE film_category
    ADD CONSTRAINT fk_filmcat2film FOREIGN KEY (film_id) REFERENCES film(film_id),
    ADD CONSTRAINT fk_filmcat2cat FOREIGN KEY (category_id) REFERENCES category(category_id);

-- /////////////////////////////////////////// Constraints //////////////////////////////////////////////////////////////
-- constraint to make sure category name is in set specified by constraint requirements
ALTER TABLE category 
ADD CONSTRAINT check_cat_name
CHECK (name IN ('Animation', 'Comedy','Family','Foreign','Sci-Fi','Travel',
				'Children','Drama','Horror','Action','Classics','Games','New',
                'Documentary','Sports','Music'));
                
-- adds film table constraints specified in constraint section 
ALTER TABLE film
ADD CONSTRAINT check_rental_rate CHECK (rental_rate BETWEEN 0.99 AND 6.99), -- rate is .99 to 6.99
ADD CONSTRAINT check_rental_duration CHECK (rental_duration BETWEEN 2 AND 8), -- duration is positive and between 2 and 8
ADD CONSTRAINT check_length CHECK (length BETWEEN 30 AND 200), -- film length is 30 to 200
ADD CONSTRAINT check_rating CHECK (rating IN('PG','G','NC-17','PG-13','R')), -- rating is within specified set
ADD CONSTRAINT check_replacement_cost CHECK (replacement_cost BETWEEN 5.00 AND 100.00), -- replacement cost specified
ADD CONSTRAINT check_special_features CHECK (special_features IN ('Behind the Scenes', 'Commentaries', 
																	'Deleted Scenes', 'Trailers')); -- special features are in the set specified. 
                                                                    
-- adds constraint to customer table to check if active
ALTER TABLE customer
ADD CONSTRAINT check_customer_active CHECK (active IN (0,1));

-- adds constraint to filter non-negatives
ALTER TABLE payment
ADD CONSTRAINT check_amount CHECK (amount >= 0);

-- adds constraint to staff table to check if staff is active 
ALTER TABLE staff
ADD CONSTRAINT check_staff_active CHECK (active IN (0,1));

-- adds constraint for rental dates to ensure the return date is after rental date 
ALTER TABLE rental
ADD CONSTRAINT check_rental_dates CHECK (return_date >= rental_date);

-- ////////////////////////////////////////////// Problem 1 /////////////////////////////////////////////////
SELECT category.name, AVG(film.length) AS average_film_length -- displays category and average film length 
FROM category
JOIN film_category on category.category_id = film_category.category_id
JOIN film on film_category.film_id = film.film_id -- joins required tables. 
GROUP BY category.name -- groups by category for average legnth in each category
ORDER BY category.name; -- orders results alphabetically 

-- ////////////////////////////////////////////// Problem 2 /////////////////////////////////////////////////
WITH AverageLengths AS ( -- CTE calculates average film length for each category will be used to find min and max values 
SELECT category.name AS category_name, AVG(film.length) AS average_film_length -- gives category.name alias category_name and the avg function alias of average_film_length
FROM category
JOIN film_category on category.category_id = film_category.category_id
JOIN film on film_category.film_id = film.film_id
GROUP BY category.name
)
SELECT 'Longest' AS length_type, -- finds cetegory with longest average film length
category_name, 
average_film_length
FROM AverageLengths
WHERE average_film_length = (SELECT MAX(average_film_length) FROM AverageLengths)
UNION ALL -- combines reults of queries for shortest and longest average lengths 
SELECT 'Shortest' AS length_type, -- finds category with shortest average film length  
category_name, average_film_length
FROM AverageLengths
WHERE average_film_length = (SELECT MIN(average_film_length) FROM AVERAGELengths);

-- ////////////////////////////////////////////// Problem 3 /////////////////////////////////////////////////        
SELECT DISTINCT customer.customer_id,customer.first_name,customer.last_name -- displays unique customer name and id for those who rented comedy no classic 
FROM customer
JOIN rental on customer.customer_id = rental.customer_id
JOIN inventory on rental.inventory_id = inventory.inventory_id
JOIN film_category ON inventory.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
WHERE category.name = 'Action' -- filters to display action movies
AND customer.customer_id NOT IN( -- filters customers from other categories
	SELECT DISTINCT customer.customer_id
    FROM customer
	JOIN rental on customer.customer_id = rental.customer_id
	JOIN inventory on rental.inventory_id = inventory.inventory_id
	JOIN film_category ON inventory.film_id = film_category.film_id
	JOIN category ON film_category.category_id = category.category_id
	WHERE category.name IN ('Comedy','Classics') -- excludes Comedy and Classic 
);
-- ////////////////////////////////////////////// Problem 4 /////////////////////////////////////////////////   
SELECT actor.actor_id,actor.first_name,actor.last_name, COUNT(film.film_id) AS movie_count -- displays actor ID name and the amount of films the actor in most english movies was in 
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film ON film_actor.film_id = film.film_id
JOIN language on film.language_id = language.language_id
WHERE language.name = 'English' -- filters the language by english
GROUP BY actor.actor_id, actor.first_name,actor.last_name
ORDER BY movie_count DESC
LIMIT 1; -- displays value with highest number of english language films

-- ////////////////////////////////////////////// Problem 5 ///////////////////////////////////////////////// 
SELECT COUNT(DISTINCT film.film_id) AS unique_movie_count -- will display unique movie count
FROM rental
JOIN inventory on rental.inventory_id = inventory.inventory_id
JOIN film on inventory.film_id = film.film_id
JOIN staff on staff.store_id = inventory.store_id -- info to tie staff to store
WHERE staff.first_name = 'Mike' -- filters results to only be handled by mike
	AND DATEDIFF(rental.return_date, rental.rental_date) = 10; -- specifies rentals with 10day difference between return date and rental date

-- ////////////////////////////////////////////// Problem 6 /////////////////////////////////////////////////
SELECT actor.first_name, actor.last_name -- displays actors first and last name
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
WHERE film_actor.film_id = ( 
	SELECT film_actor.film_id FROM film_actor
    GROUP BY film_actor.film_id
    ORDER BY COUNT(DISTINCT film_actor.actor_id) DESC -- orders grouped results by count of distinct actors so film with the most comes first
    LIMIT 1 -- highest value is the only one displayed 
)
ORDER BY actor.last_name; -- alphabetical ordering 
