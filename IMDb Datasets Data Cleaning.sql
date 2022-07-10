-- Viewing the IMDb horror movie dataset

SELECT * 
FROM PortfolioProject.dbo.[IMDb.horror]

/* 
- The "isAdult" and "endYear" columns won't be required
- There are nulls in the starYear column
- There are "\N" values in the runtimeMinutes column
*/


-- Deleting unused columns

ALTER TABLE PortfolioProject.dbo.[IMDb.horror]
DROP COLUMN isAdult, endYear


-- Checking for nulls in the startYear

SELECT *
FROM PortfolioProject.dbo.[IMDb.horror]
WHERE startYear is null

/* 85 rows contained a null startYear. We won't need to delete these rows as we can filter it out when creating the new dataset */


-- Checking for duplicate values

SELECT tconst, COUNT(tconst)
FROM PortfolioProject.dbo.[IMDb.horror]
GROUP BY tconst
HAVING COUNT(tconst) > 1

/* There were no duplicate rows in the dataset */


-- Creating new dataset (horror movies released between 2010 and 2019)

SELECT tconst,
primaryTitle,
originalTitle,
startYear
INTO horror_movies_cleaned
FROM PortfolioProject.dbo.[IMDb.horror]
WHERE startYear between 2010 and 2019


-- Viewing the IMDb ratings dataset

SELECT * 
FROM PortfolioProject.dbo.[IMDb.ratings]


-- Checking for nulls in the averageRating and numVotes

Select *
FROM PortfolioProject.dbo.[IMDb.ratings]
Where averageRating is null

Select *
FROM PortfolioProject.dbo.[IMDb.ratings]
Where numVotes is null

/* There were no null values in the averageRating and numVotes columns */


-- Checking for duplicate values

SELECT tconst, COUNT(tconst)
FROM PortfolioProject.dbo.[IMDb.ratings]
GROUP BY tconst
HAVING COUNT(tconst) > 1

/* There were no duplicate rows in the dataset */


-- Checking the filtering functionality of IMDb ratings dataset

SELECT * 
FROM PortfolioProject.dbo.[IMDb.ratings]
WHERE averageRating > 8

SELECT * 
FROM PortfolioProject.dbo.[IMDb.ratings]
WHERE numVotes > 1000

/* The filtering didn't work for the averageRating because it is in a varchar format. It will be converted to a decimal format. */

SELECT averageRating,
CAST([averageRating] AS DECIMAL(3,1)) AS decaverageRating
FROM PortfolioProject.dbo.[IMDb.ratings]


-- Creating new dataset (ratings dataset with correct averageRating format)

SELECT tconst,
CAST([averageRating] AS DECIMAL(3,1)) AS decaverageRating,
numVotes
INTO ratings_cleaned
FROM PortfolioProject.dbo.[IMDb.ratings]

SELECT *
FROM ratings_cleaned


-- Viewing the IMDb principals dataset

SELECT TOP 1000 * 
FROM PortfolioProject.dbo.[IMDb.principals]

/* The "job" and "characters" columns won't be required */


-- Viewing the different categories

SELECT category, COUNT(category)
FROM PortfolioProject.dbo.[IMDb.principals]
GROUP BY category

/* For our analysis, we are only interested in the actor and actress categories */


-- Creating new dataset (principals dataset with only actors and actresses)

SELECT tconst,
ordering,
nconst,
category
INTO principals_category_cleaned
FROM PortfolioProject.dbo.[IMDb.principals]
WHERE category = 'actor' or category = 'actress'


-- Joining the cleaned horror movies and ratings datasets

SELECT horror.tconst,
horror.primaryTitle,
horror.originalTitle,
horror.startYear,
ratings.decaverageRating,
ratings.numVotes
FROM horror_movies_cleaned AS horror
LEFT JOIN ratings_cleaned AS ratings
ON horror.tconst = ratings.tconst

/* There are nulls in the decaverageRating and numVotes columns */

SELECT horror.tconst,
horror.primaryTitle,
horror.originalTitle,
horror.startYear,
ratings.decaverageRating,
ratings.numVotes
FROM horror_movies_cleaned AS horror
LEFT JOIN ratings_cleaned AS ratings
ON horror.tconst = ratings.tconst
WHERE ratings.decaverageRating is null or ratings.numVotes is null

/* 55 rows contained a null decaverageRating or numVotes. We won't need to delete these rows as we can filter it out when creating the new dataset */


-- Filtering the joined horror movies and ratings datasets

SELECT horror.tconst,
horror.primaryTitle,
horror.originalTitle,
horror.startYear,
ratings.decaverageRating,
ratings.numVotes
FROM horror_movies_cleaned AS horror
LEFT JOIN ratings_cleaned AS ratings
ON horror.tconst = ratings.tconst
WHERE decaverageRating is not null AND numVotes >= 500

/* There are 258 movies that don't have null rating. When we filter it for movies where there are at least 500 votes, this decreases to 115 movies */


-- Joining the principals dataset

SELECT horror.tconst,
horror.primaryTitle,
horror.originalTitle,
horror.startYear,
ratings.decaverageRating,
ratings.numVotes,
principals.nconst,
principals.category
FROM horror_movies_cleaned AS horror
LEFT JOIN ratings_cleaned AS ratings
ON horror.tconst = ratings.tconst
LEFT JOIN principals_category_cleaned AS principals
ON horror.tconst = principals.tconst
WHERE decaverageRating is not null AND numVotes >= 500

/* We also need to include an additional column to determine the number of appearance credits that the actors / actresses has */


-- Creating new dataset (with an appearance credits column)

SELECT nconst,
COUNT(nconst) AS appearanceCredits
INTO principals_appearance_credits
FROM principals_category_cleaned
GROUP BY nconst


-- Creating new dataset (joining the appearance credits column to the horror movies, ratings and principals datasets) 

SELECT horror.tconst,
horror.primaryTitle,
horror.originalTitle,
horror.startYear,
ratings.decaverageRating,
ratings.numVotes,
principals.nconst,
principals.category,
credits.appearanceCredits
INTO final_movies_dataset
FROM horror_movies_cleaned AS horror
LEFT JOIN ratings_cleaned AS ratings
ON horror.tconst = ratings.tconst
LEFT JOIN principals_category_cleaned AS principals
ON horror.tconst = principals.tconst
LEFT JOIN principals_appearance_credits AS credits
ON principals.nconst = credits.nconst
WHERE decaverageRating is not null AND numVotes >= 500
ORDER BY primaryTitle, appearanceCredits DESC

/* Now that we have cleaned and joined the IMDb.horror, IMDb.principals and IMDb.ratings datasets, we can select the columns that we want to use for our analysis */

SELECT primaryTitle,
startYear,
decaverageRating,
numVotes,
nconst,
category,
appearanceCredits
FROM final_movies_dataset