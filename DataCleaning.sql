
-- --------------------------------------------------
-- DATA CLEANING PROJECT: Layoffs Dataset (MySQL)
-- --------------------------------------------------

-- GOAL: 
-- Remove duplicates, standardize data, handle null/blanks, format dates, and clean up columns

-- STEP 1: Drop and recreate the first staging table
DROP TABLE IF EXISTS layoffs_staging;
CREATE TABLE layoffs_staging LIKE layoffs;

-- STEP 2: Insert original data into the first staging table
TRUNCATE TABLE layoffs_staging;
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- STEP 3: Drop and recreate the second staging table with an extra column 'row_num'
DROP TABLE IF EXISTS layoffs_staging2;
CREATE TABLE layoffs_staging2 (
    `company` TEXT, 
    `location` TEXT,
    `industry` TEXT, 
    `total_laid_off` INT DEFAULT NULL,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT DEFAULT NULL,
    `row_num` INT
);

-- STEP 4: Insert data into layoffs_staging2 and assign row numbers to detect duplicates
INSERT INTO layoffs_staging2 (
    company, location, industry, total_laid_off, percentage_laid_off,
    date, stage, country, funds_raised_millions, row_num
)
SELECT 
    company, location, industry, total_laid_off, percentage_laid_off,
    date, stage, country, funds_raised_millions,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

-- STEP 5: View duplicate rows (row_num > 1)
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- STEP 6: Disable safe update mode (required to allow DELETE without primary key)
SET SQL_SAFE_UPDATES = 0;

-- STEP 7: Delete duplicate rows
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

-- --------------------------------------------------
-- STEP 8: STANDARDIZE THE DATA
-- --------------------------------------------------

-- Trim whitespace from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize variations of 'Crypto' in industry column
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'CRYPTO%';

-- Clean country values by removing trailing periods (e.g., 'United States.')
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- --------------------------------------------------
-- STEP 9: FORMAT THE DATE COLUMN
-- --------------------------------------------------

-- Convert string-formatted dates to DATE type
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change column type from TEXT to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- --------------------------------------------------
-- STEP 10: HANDLE NULLS AND BLANK VALUES
-- --------------------------------------------------

-- View rows with both total_laid_off and percentage_laid_off missing
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- View rows with missing or blank industry
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = ' ';

-- View data for a specific company
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Fill missing industry values based on matching company name
SELECT t1.industry AS target_null, t2.industry AS source_value
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = ' ')
  AND t2.industry IS NOT NULL;

-- Apply updates based on matching companies
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = ' ')
  AND t2.industry IS NOT NULL;

-- View rows with blank or null company names
SELECT * 
FROM layoffs_staging2
WHERE company IS NULL
   OR company = ' ';

-- --------------------------------------------------
-- STEP 11: FINAL CLEANING STEPS
-- --------------------------------------------------

-- Delete rows where both layoff fields are NULL (no useful info)
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Drop the row_num column (no longer needed)
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final clean dataset preview
SELECT * 
FROM layoffs_staging2;

-- --------------------------------------------------
-- DONE: Dataset is cleaned and ready for analysis.
-- --------------------------------------------------
