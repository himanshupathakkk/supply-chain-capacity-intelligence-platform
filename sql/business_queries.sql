# business_queries.sql

```sql
-- =========================================================
-- SUPPLY CHAIN CAPACITY INTELLIGENCE PLATFORM
-- Business Analytics & Operational Intelligence Queries
-- =========================================================


-- =========================================================
-- SECTION 1: CORE KPI ENGINEERING
-- Purpose:
-- Build foundational delivery and SLA KPIs for operational analysis.
-- =========================================================

-- Query 1: Delivery Delay & SLA Breach Engineering
-- Calculates delivery delays, SLA breach flags, and delivery duration.

SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    DATE_PART(
        'day',
        order_delivered_customer_date - order_estimated_delivery_date
    ) AS delivery_delay_days,

    CASE
        WHEN DATE_PART(
            'day',
            order_delivered_customer_date - order_estimated_delivery_date
        ) > 0
        THEN 1
        ELSE 0
    END AS sla_breach_flag,

    DATE_PART(
        'day',
        order_delivered_customer_date - order_purchase_timestamp
    ) AS delivery_duration_days

FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- Query 2: Delivery Status Classification
-- Categorizes deliveries into Early, On-Time, or Delayed.

SELECT
    order_id,

    DATE_PART(
        'day',
        order_delivered_customer_date - order_estimated_delivery_date
    ) AS delivery_delay_days,

    CASE
        WHEN DATE_PART(
            'day',
            order_delivered_customer_date - order_estimated_delivery_date
        ) > 0
        THEN 'Delayed'

        WHEN DATE_PART(
            'day',
            order_delivered_customer_date - order_estimated_delivery_date
        ) < 0
        THEN 'Early'

        ELSE 'On-Time'
    END AS delivery_status

FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- Query 3: Overall Operational KPIs
-- Generates executive-level delivery performance KPIs.

SELECT
    COUNT(order_id) AS total_orders,

    ROUND(
        AVG(
            DATE_PART(
                'day',
                order_delivered_customer_date - order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_duration,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight_cost,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(order_id),
        2
    ) AS sla_breach_rate

FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
WHERE order_delivered_customer_date IS NOT NULL;


-- =========================================================
-- SECTION 2: DELIVERY PERFORMANCE ANALYSIS
-- Purpose:
-- Analyze operational growth, delivery reliability, and scaling trends.
-- =========================================================

-- Query 4: Monthly Order Growth Trend
-- Tracks operational order growth and cumulative business expansion.

SELECT
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS order_month,

    COUNT(order_id) AS total_orders,

    SUM(COUNT(order_id)) OVER (
        ORDER BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
    ) AS cumulative_orders

FROM orders
GROUP BY order_month
ORDER BY order_month;


-- Query 5: Monthly SLA Breach Trend
-- Monitors delivery reliability trends over time.

SELECT
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS order_month,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(order_id),
        2
    ) AS sla_breach_rate

FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY order_month
ORDER BY order_month;


-- Query 6: Moving Average SLA Trend
-- Smooths operational SLA volatility for trend analysis.

WITH monthly_sla AS (

    SELECT
        TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS order_month,

        ROUND(
            100.0 * SUM(
                CASE
                    WHEN order_delivered_customer_date > order_estimated_delivery_date
                    THEN 1
                    ELSE 0
                END
            ) / COUNT(order_id),
            2
        ) AS sla_breach_rate

    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
    GROUP BY order_month
)

SELECT
    order_month,
    sla_breach_rate,

    ROUND(
        AVG(sla_breach_rate) OVER (
            ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_sla

FROM monthly_sla
ORDER BY order_month;


-- =========================================================
-- SECTION 3: OPERATIONAL ROOT CAUSE ANALYSIS (RCA)
-- Purpose:
-- Identify delivery bottlenecks and regional SLA risk drivers.
-- =========================================================

-- Query 7: Customer-State SLA Risk Analysis
-- Identifies high-risk delivery regions based on SLA breaches.

SELECT
    c.customer_state,

    COUNT(o.order_id) AS total_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS sla_breach_rate,

    DENSE_RANK() OVER (
        ORDER BY
            ROUND(
                100.0 * SUM(
                    CASE
                        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                        THEN 1
                        ELSE 0
                    END
                ) / COUNT(o.order_id),
                2
            ) DESC
    ) AS risk_rank

FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY sla_breach_rate DESC;


-- Query 8: Customer-State Delivery Duration Analysis
-- Evaluates regional delivery efficiency and SLA reliability.

SELECT
    c.customer_state,

    COUNT(o.order_id) AS total_orders,

    ROUND(
        AVG(
            DATE_PART(
                'day',
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_duration,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS sla_breach_rate

FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY sla_breach_rate DESC;


-- Query 9: Peak Demand Operational Stress Analysis
-- Measures SLA performance during high-volume operational periods.

SELECT
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS order_month,

    COUNT(order_id) AS total_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(order_id),
        2
    ) AS sla_breach_rate

FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY order_month
ORDER BY total_orders DESC;


-- =========================================================
-- SECTION 4: FREIGHT & LOGISTICS ANALYSIS
-- Purpose:
-- Evaluate freight inefficiencies and logistics risk exposure.
-- =========================================================

-- Query 10: Freight Category vs SLA Breach Analysis
-- Examines delivery reliability across freight cost bands.

WITH freight_analysis AS (

    SELECT
        o.order_id,
        oi.freight_value,

        CASE
            WHEN oi.freight_value >= 30 THEN 'High Freight'
            WHEN oi.freight_value >= 15 THEN 'Medium Freight'
            ELSE 'Low Freight'
        END AS freight_category,

        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END AS sla_breach_flag

    FROM orders o
    JOIN order_items oi
    ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
)

SELECT
    freight_category,
    COUNT(order_id) AS total_shipments,

    ROUND(
        100.0 * AVG(sla_breach_flag),
        2
    ) AS sla_breach_rate

FROM freight_analysis
GROUP BY freight_category
ORDER BY sla_breach_rate DESC;


-- Query 11: Freight Cost vs SLA Reliability by State
-- Identifies regions combining high freight costs and poor delivery reliability.

SELECT
    c.customer_state,

    ROUND(
        AVG(oi.freight_value),
        2
    ) AS avg_freight_cost,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS breach_rate,

    COUNT(o.order_id) AS total_shipments

FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY breach_rate DESC;


-- =========================================================
-- SECTION 5: SELLER PERFORMANCE & FULFILLMENT ANALYSIS
-- Purpose:
-- Evaluate seller concentration and fulfillment dependency risk.
-- =========================================================

-- Query 12: Seller-State Breach Contribution
-- Measures seller-region contribution to operational SLA breaches.

SELECT
    s.seller_state,

    COUNT(o.order_id) AS total_shipments,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS breached_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS breach_percentage

FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN sellers s
ON oi.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state
ORDER BY breach_percentage DESC;


-- Query 13: Seller Operational Monitoring
-- Identifies operationally dominant seller regions.

SELECT
    s.seller_state,

    COUNT(o.order_id) AS total_shipments,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS breach_rate

FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN sellers s
ON oi.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state
ORDER BY total_shipments DESC;


-- =========================================================
-- SECTION 6: EXECUTIVE INSIGHTS & STRATEGIC ANALYSIS
-- Purpose:
-- Generate leadership-level operational intelligence.
-- =========================================================

-- Query 14: Regional Logistics Capacity Planning
-- Identifies states requiring logistics capacity expansion.

SELECT
    c.customer_state,

    COUNT(o.order_id) AS total_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS sla_breach_rate

FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(o.order_id) > 1000
ORDER BY sla_breach_rate DESC;


-- Query 15: Strategic Operational Risk Matrix
-- Combines delivery duration and SLA reliability for executive monitoring.

SELECT
    c.customer_state,

    COUNT(o.order_id) AS total_orders,

    ROUND(
        AVG(
            DATE_PART(
                'day',
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_duration,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS breach_rate

FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY breach_rate DESC, avg_delivery_duration DESC;

```
