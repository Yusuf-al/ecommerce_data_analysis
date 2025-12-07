# Advanced E‑Commerce Data Warehouse & Analytics Project  

## 📌 Overview  
This repository showcases a complete end‑to‑end **E‑Commerce Data Warehouse & Data Analytics Project** built using:  

- **MS SQL Server (ETL + DWH + Data Marts)**  
- **Python (Optional ETL Automation)**  
- **Tableau/Power BI (Dashboarding)**  

The goal of this project is to demonstrate strong **data engineering**, **data modeling**, and **analytics engineering skills** through a real-world retail dataset workflow.

---

## 🏗️ Project Architecture  

### **1. Raw Data → Staging → Silver → Gold Layers**
The project follows a **medallion architecture**:

```
Bronze (Raw Data)
│
├── Silver (Cleaned, Standardized Data)
│
└── Gold (Star Schema + Analytics Data Marts)
```

---

## 📦 Data Warehouse  

### **Data Warehouse Star Schema**
- **Fact Tables:**  
  - fact_orders  
  - fact_order_items  
  - fact_payments  
  - fact_reviews  

- **Dimension Tables:**  
  - dim_customers  
  - dim_products  
  - dim_sellers  
  - dim_dates  

> Includes surrogate keys, SCD logic, and integrity constraints.

---

## 📊 Data Modeling  
The project follows a **Kimball Dimensional Modeling approach**:

- Star Schema  
- Surrogate keys  
- Conformed dimensions  
- Slowly Changing Dimensions (SCD)  
- Date Dimension with full calendar hierarchy  

---

## 🔄 ETL / Data Integration  

### ETL Pipeline Tasks
- Data cleaning (trimming, null handling, standardizing city/state names)  
- Surrogate key generation  
- Deduplication of customer and seller records  
- Joining and transforming ecommerce order lifecycle  
- Mapping payments, reviews, shipment data  

---

## 🔀 Data Flow Diagram  

```
Source CSVs
    ↓  
SQL Server Staging  
    ↓  
Transformations (CTEs, Deduplication, Cleaning)  
    ↓  
DWH Star Schema  
    ↓  
Analytics Data Marts  
```

---

## 📈 Analytics & Business Use‑Cases  

### **1. Market Share Analysis**
- Category share of total revenue  
- Region share of seller revenue  
- State‑wise contribution  

Involves:  
✔ Window functions  
✔ Aggregations  
✔ Ranking functions  

---

### **2. Product Affinity Analysis**  
**Objective:** Identify categories frequently bought together  
- Co-occurrence matrix  
- Category bundles  
- Market basket insights  

Techniques Used:  
✔ Self‑joins on order items  
✔ Window functions  
✔ Category-level association scoring  

---

### **3. YTD Performance Dashboard**  
Metrics included:  
- YTD Revenue  
- YTD Orders  
- YTD New Customers  
- Comparison vs Previous Year  
- YTD variance & % change  

SQL features used:  
✔ Window functions (SUM OVER PARTITION)  
✔ Date filtering  
✔ Prior‑year lookups  

---

## 📂 Repository Structure  

```
├── /sql
│   ├── staging_scripts.sql
│   ├── silver_layer.sql
│   ├── gold_star_schema.sql
│   ├── analytics_queries.sql
│
├── /models
│   ├── data_model.png
│   ├── data_flow.png
│   ├── data_warehouse_schema.png
│
├── README.md
```

---

## 🖼️ Data Warehouse & Modeling Images  
(Place images inside `/models` folder and embed them like below)

```md
![Data Warehouse](models/data_warehouse_schema.png)
![Data Model](models/data_model.png)
![Data Integration](models/data_flow.png)
```

---

## 🚀 Key Skills Demonstrated  

### **Data Engineering**
- SQL Server ETL  
- Data cleaning + validation  
- Dimensional modeling  

### **Analytics Engineering**
- Window Functions  
- CTE-based transformations  
- Data Marts  
- KPI Framework  

### **Business Analytics**
- Market share modeling  
- Product affinity  
- YTD dashboard metrics  

---

## 🧠 Why This Project Stands Out  
✔ Real‑world e‑commerce lifecycle  
✔ Enterprise‑grade DWH design  
✔ Complex SQL with window functions  
✔ Business‑driven analytics use‑cases  
✔ Production-ready documentation  

---

## 🙌 Contributions  
Feel free to submit PRs or open issues!

## ⭐ If you like this project, consider giving it a star!  
