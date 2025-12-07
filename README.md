# Advanced E‑Commerce Data Warehouse & Analytics Project  

## 📌 Overview  
This repository showcases a complete end‑to‑end **E‑Commerce Data Warehouse & Data Analytics Project** built using:  

- **MS SQL Server (ETL + DWH + Data Marts)**
- 
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
  - fact_order_items  
  - fact_payments  
  - fact_reviews  

- **Dimension Tables:**  
  - dim_customers  
  - dim_products  
  - dim_sellers  
  - dim_dates
  - dim_geoloaction  

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

## 🔄 ETL 

### ETL Pipeline Tasks
- Data cleaning (trimming, null handling, standardizing city/state names)  
- Surrogate key generation  
- Deduplication of customer and seller records  
- Joining and transforming e-commerce order lifecycle  
- Mapping payments, reviews, shipment data  

---
## 🏪 Data Warehouse 
<img width="761" height="530" alt="BE_DWH" src="https://github.com/user-attachments/assets/6fb305c9-de70-422e-acf3-c45ba1d4e620" />

## 🔀 Data Flow Diagram  
<img width="1012" height="581" alt="BE_data-flow (1)" src="https://github.com/user-attachments/assets/3ce4547d-cab5-4239-8867-0ea44a1cf301" />

## 📃 Data Integration
<img width="729" height="681" alt="data-intregation_model (1)" src="https://github.com/user-attachments/assets/dca55d41-2f9b-4181-b9e4-8f0953f29f2a" />

## 📊 Data Model
<img width="741" height="741" alt="BE_data_model (1)" src="https://github.com/user-attachments/assets/ce14137b-145e-4e25-bafa-fd6994dcda8a" />

## 📈 Analytics & Business Use‑Cases  

### **CHANGE-OVER-TIME ANALYSIS**
- Track financial performance growth over time
- Understand customer acquisition and retention patterns
- Identify seasonal demand fluctuations for inventory planning

### **CUMULATIVE ANALYSIS**
- Track cumulative revenue trend  
- calculate running totals & running averages
- Track growth trends and measure year-over-year performance

### **DATA SEGMENTATION**
- Find product categories purchased together in the same order
- Build category-to-category affinity matrix for bundle opportunities

### **PERFORMANCE ANALYSIS**
- Evaluate seller performance
- Creates actionable segmentation for different seller groups
- Track how product performance changes over time after launch
- Identify product lifecycle patterns and category-level revenue trends

### **PART-TO-WHOLE ANALYSIS**
- Category share of total revenue  
- Region share of seller revenue  
- State‑wise contribution  

Advanced SQL features used: 
✔ Window functions
✔ Aggregations
✔ Ranking functions
✔ Subqueries
✔ CTE (Common Table Expressions)
✔ Date filtering  

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
- Change Over Time
- Cumulative Analysis
- Performance Analysis
- Part-To-Whole Analysis
- Data Segmentation  

---

## 🧠 Why This Project Stands Out  
✔ Real‑world e‑commerce lifecycle  
✔ Enterprise‑grade DWH design  
✔ Complex SQL with window functions  
✔ Business‑driven analytics use‑cases  
✔ Production-ready documentation  

