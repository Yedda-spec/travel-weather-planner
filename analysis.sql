-- =========================================================
-- Famous vs Hidden Gems: When Should You Travel?
-- PostgreSQL analysis (database: travel_planner)
-- =========================================================


-- ---------- 1. Tables ----------

CREATE TABLE destinations (
    pair_id  INTEGER,
    name     TEXT PRIMARY KEY,
    country  TEXT,
    type     TEXT,          -- 'famous' or 'hidden'
    lat      NUMERIC,
    lon      NUMERIC
);

CREATE TABLE weather (
    name            TEXT,
    date            DATE,
    year            INTEGER,
    month           INTEGER,
    temp_max        NUMERIC,
    temp_min        NUMERIC,
    rain_mm         NUMERIC,
    sunshine_hours  NUMERIC
);

-- Data was loaded from:
--   data/raw/destinations.csv        -> destinations
--   data/processed/weather_clean.csv -> weather

-- Quick check: expect 16 and 29216
SELECT COUNT(*) FROM destinations;
SELECT COUNT(*) FROM weather;


-- ---------- 2. Typical weather per destination and month (2021-2025 average) ----------

CREATE VIEW monthly_climate AS
SELECT
    name,
    month,
    ROUND(AVG(temp_max), 1)        AS avg_temp_max,
    ROUND(AVG(temp_min), 1)        AS avg_temp_min,
    ROUND(AVG(CASE WHEN rain_mm >= 1 THEN 1 ELSE 0 END) * 100, 0) AS rainy_days_pct,
    ROUND(AVG(sunshine_hours), 1)  AS avg_sunshine_hours
FROM weather
GROUP BY name, month;


-- ---------- 3. Comfort score (0-100) ----------
-- Temperature: 35 points if the average daily max is 20-30°C, minus 3.5 per degree outside
-- Rain:        40 points x share of dry days
-- Sunshine:    25 points for 10+ hours of sunshine, scaled below that

CREATE VIEW comfort_scores AS
SELECT
    name,
    month,
    avg_temp_max,
    rainy_days_pct,
    avg_sunshine_hours,
    ROUND(
        GREATEST(0, 35 - 3.5 * CASE
            WHEN avg_temp_max < 20 THEN 20 - avg_temp_max
            WHEN avg_temp_max > 30 THEN avg_temp_max - 30
            ELSE 0
        END)
        + 40 * (1 - rainy_days_pct / 100.0)
        + 25 * LEAST(avg_sunshine_hours, 10) / 10.0
    , 0) AS comfort_score
FROM monthly_climate;


-- ---------- 4. Best month for each destination ----------

WITH ranked AS (
    SELECT
        name,
        month,
        comfort_score,
        RANK() OVER (PARTITION BY name ORDER BY comfort_score DESC) AS rnk
    FROM comfort_scores
)
SELECT
    name,
    TO_CHAR(TO_DATE(month::text, 'MM'), 'Mon') AS best_month,
    comfort_score
FROM ranked
WHERE rnk = 1
ORDER BY comfort_score DESC;


-- ---------- 5. Famous vs hidden gem, month by month ----------

CREATE VIEW pair_comparison AS
SELECT
    d.pair_id,
    c.month,
    MAX(CASE WHEN d.type = 'famous' THEN d.name END)          AS famous_place,
    MAX(CASE WHEN d.type = 'famous' THEN c.comfort_score END) AS famous_score,
    MAX(CASE WHEN d.type = 'hidden' THEN d.name END)          AS hidden_place,
    MAX(CASE WHEN d.type = 'hidden' THEN c.comfort_score END) AS hidden_score
FROM comfort_scores c
JOIN destinations d ON c.name = d.name
GROUP BY d.pair_id, c.month;

-- Strict version: months where the hidden gem scores equal or higher
SELECT
    famous_place,
    hidden_place,
    COUNT(*) FILTER (WHERE hidden_score >= famous_score) AS months_hidden_as_good_or_better
FROM pair_comparison
GROUP BY famous_place, hidden_place
ORDER BY months_hidden_as_good_or_better DESC;

-- Fairer version: "similar" means within 5 points, plus the average difference
SELECT
    famous_place,
    hidden_place,
    COUNT(*) FILTER (WHERE hidden_score >= famous_score - 5) AS months_similar_or_better,
    ROUND(AVG(hidden_score - famous_score), 1)              AS avg_score_difference
FROM pair_comparison
GROUP BY famous_place, hidden_place
ORDER BY months_similar_or_better DESC;


-- ---------- 6. Export for Tableau (saved as data/processed/tableau_comfort.csv) ----------

SELECT
    c.name,
    d.country,
    d.type,
    d.pair_id,
    d.lat,
    d.lon,
    c.month,
    TO_CHAR(TO_DATE(c.month::text, 'MM'), 'Mon') AS month_name,
    c.avg_temp_max,
    c.rainy_days_pct,
    c.avg_sunshine_hours,
    c.comfort_score,
    CASE
        WHEN c.comfort_score >= MAX(c.comfort_score) OVER (PARTITION BY c.name) - 5
        THEN 'Yes' ELSE 'No'
    END AS good_month
FROM comfort_scores c
JOIN destinations d ON c.name = d.name
ORDER BY d.pair_id, c.name, c.month;
