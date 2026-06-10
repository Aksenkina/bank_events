-- SQL-ЗАПРОСЫ ДЛЯ ПРОДУКТОВОЙ АНАЛИТИКИ
-- Воронка + Retention (1,3,7) + DAU + MAU
-- 1. Конверсионная воронка

SELECT 
    event_type,
    COUNT(DISTINCT user_id) as users_count
FROM df_events
WHERE event_type IN ('app_open', 'view_card_offer', 'apply_card', 'card_approved', 'first_transfer')
GROUP BY event_type
ORDER BY 
    CASE event_type
        WHEN 'app_open' THEN 1
        WHEN 'view_card_offer' THEN 2
        WHEN 'apply_card' THEN 3
        WHEN 'card_approved' THEN 4
        WHEN 'first_transfer' THEN 5
    END


-- 2. Retention Day 1, 3, 7

WITH first_activity AS (
    SELECT 
        user_id,
        MIN(event_date) as first_date
    FROM df_events
    GROUP BY user_id
),
user_retention AS (
    SELECT 
        f.user_id,
        f.first_date,
        MAX(CASE WHEN e.event_date = f.first_date + INTERVAL '1' DAY THEN 1 ELSE 0 END) as day1,
        MAX(CASE WHEN e.event_date = f.first_date + INTERVAL '3' DAY THEN 1 ELSE 0 END) as day3,
        MAX(CASE WHEN e.event_date = f.first_date + INTERVAL '7' DAY THEN 1 ELSE 0 END) as day7
    FROM first_activity f
    LEFT JOIN df_events e ON f.user_id = e.user_id
    GROUP BY f.user_id, f.first_date
)
SELECT 
    first_date as cohort_date,
    COUNT(*) as total_users,
    ROUND(100.0 * SUM(day1) / COUNT(*), 1) as retention_day1,
    ROUND(100.0 * SUM(day3) / COUNT(*), 1) as retention_day3,
    ROUND(100.0 * SUM(day7) / COUNT(*), 1) as retention_day7
FROM user_retention
GROUP BY first_date
ORDER BY first_date
LIMIT 10


-- 3. Daily Active Users (DAU)

SELECT 
    event_date,
    COUNT(DISTINCT user_id) as dau
FROM df_events
WHERE event_type = 'app_open'
GROUP BY event_date
ORDER BY event_date
LIMIT 10


-- 4. Monthly Active Users (MAU)

SELECT 
    DATE_TRUNC('month', event_date) as month,
    COUNT(DISTINCT user_id) as MAU
FROM df_events
WHERE event_type = 'app_open'
GROUP BY DATE_TRUNC('month', event_date)
ORDER BY month


-- 5. Конверсия по сегментам

SELECT 
    u.segment,
    COUNT(DISTINCT u.user_id) as total_users,
    COUNT(DISTINCT CASE WHEN e.event_type = 'first_transfer' THEN e.user_id END) as users_with_transfer,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_type = 'first_transfer' THEN e.user_id END) / COUNT(DISTINCT u.user_id), 1) as conversion_rate
FROM df_users u
LEFT JOIN df_events e ON u.user_id = e.user_id
GROUP BY u.segment
ORDER BY conversion_rate DESC


-- 6. Топ часы активности

SELECT 
    event_hour,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(*) as total_events
FROM df_events
WHERE event_type = 'app_open'
GROUP BY event_hour
ORDER BY unique_users DESC
LIMIT 5
