# Key DAX Measures

This document contains the core DAX measures used in the **Supply Chain Capacity Intelligence Platform** Power BI dashboard.

These measures were designed to evaluate:
- Delivery reliability
- SLA adherence
- Freight efficiency
- Operational performance
- Regional logistics risk

---

# 1. Total Orders

```DAX
Total Orders =
COUNT('public orders'[order_id])
```

### Purpose
Calculates the total number of processed customer orders.

---

# 2. SLA Breach Rate

```DAX
SLA Breach Rate =

DIVIDE(

    CALCULATE(

        COUNTROWS('public orders'),

        'public orders'[order_delivered_customer_date]
        >
        'public orders'[order_estimated_delivery_date]

    ),

    COUNTROWS('public orders'),

    0

) * 100
```

### Purpose
Measures the percentage of orders delivered after the promised SLA timeline.

---

# 3. Avg Delivery Duration

```DAX
Avg Delivery Duration =

AVERAGEX(

    'public orders',

    DATEDIFF(

        'public orders'[order_purchase_timestamp],

        'public orders'[order_delivered_customer_date],

        DAY

    )

)
```

### Purpose
Calculates the average number of days required to complete deliveries.

---

# 4. Early Delivery %

```DAX
Early Delivery % =

DIVIDE(

    CALCULATE(

        COUNTROWS('public orders'),

        'public orders'[order_delivered_customer_date]
        <
        'public orders'[order_estimated_delivery_date]

    ),

    COUNTROWS('public orders'),

    0

) * 100
```

### Purpose
Measures the percentage of orders delivered earlier than the estimated delivery date.

---

# 5. Avg Freight Cost

```DAX
Avg Freight Cost =

AVERAGE(
    'public order_items'[freight_value]
)
```

### Purpose
Calculates the average freight cost incurred per shipment.

---

# 6. Delayed Orders

```DAX
Delayed Orders =

CALCULATE(

    COUNTROWS('public orders'),

    'public orders'[order_delivered_customer_date]
    >
    'public orders'[order_estimated_delivery_date]

)
```

### Purpose
Counts the total number of delayed deliveries.

---

# 7. On-Time Orders

```DAX
On-Time Orders =

CALCULATE(

    COUNTROWS('public orders'),

    'public orders'[order_delivered_customer_date]
    =
    'public orders'[order_estimated_delivery_date]

)
```

### Purpose
Calculates orders delivered exactly on the estimated delivery date.

---

# 8. Early Orders

```DAX
Early Orders =

CALCULATE(

    COUNTROWS('public orders'),

    'public orders'[order_delivered_customer_date]
    <
    'public orders'[order_estimated_delivery_date]

)
```

### Purpose
Calculates the total number of early deliveries.

---

# 9. Avg Delivery Delay

```DAX
Avg Delivery Delay =

AVERAGEX(

    FILTER(

        'public orders',

        'public orders'[order_delivered_customer_date]
        >
        'public orders'[order_estimated_delivery_date]

    ),

    DATEDIFF(

        'public orders'[order_estimated_delivery_date],

        'public orders'[order_delivered_customer_date],

        DAY

    )

)
```

### Purpose
Measures the average delay duration for breached SLA orders.

---

# 10. Monthly Orders

```DAX
Monthly Orders =

CALCULATE(

    COUNT('public orders'[order_id]),

    ALLEXCEPT(

        'public orders',

        'public orders'[order_purchase_timestamp]

    )

)
```

### Purpose
Tracks monthly operational order volume trends.

---

# 11. High Freight Orders

```DAX
High Freight Orders =

CALCULATE(

    COUNTROWS('public order_items'),

    'public order_items'[freight_value] >= 30

)
```

### Purpose
Identifies shipments associated with elevated freight costs.

---

# 12. Delivery Status

```DAX
Delivery Status =

SWITCH(

    TRUE(),

    'public orders'[order_delivered_customer_date]
    >
    'public orders'[order_estimated_delivery_date],
    "Delayed",

    'public orders'[order_delivered_customer_date]
    <
    'public orders'[order_estimated_delivery_date],
    "Early",

    "On-Time"

)
```

### Purpose
Classifies deliveries into operational delivery categories.

---

# 13. Customer State Risk Rank

```DAX
Customer State Risk Rank =

RANKX(

    ALL('public customers'[customer_state]),

    [SLA Breach Rate],

    ,

    DESC

)
```

### Purpose
Ranks customer states based on SLA breach exposure.

---

# 14. Freight-to-Delay Ratio

```DAX
Freight-to-Delay Ratio =

DIVIDE(

    [Avg Freight Cost],

    [Avg Delivery Delay],

    0

)
```

### Purpose
Measures freight spending efficiency relative to delivery delays.

---

# 15. Delivery Efficiency Score

```DAX
Delivery Efficiency Score =

(100 - [SLA Breach Rate])
+
[Early Delivery %]
```

### Purpose
Provides a simplified operational efficiency indicator combining SLA reliability and early delivery performance.

---

# Dashboard Usage

These measures power:
- KPI Cards
- SLA Trend Analysis
- Operational RCA Visuals
- Freight Intelligence Charts
- Strategic Recommendation Tables

within the Power BI dashboard environment.