# Olist Customer Satisfaction: A Predictive Modeling Approach

## 🎯 Executive Summary
This project analyzes **91,546 Brazilian e-commerce orders** to determine the primary drivers of customer satisfaction. Through a combination of statistical auditing and Random Forest modeling, I discovered that while **Logistics (Delivery Delay and Freight Cost)** are the most influential predictors, they only explain a fraction of customer sentiment. This suggests that "soft" factors, such as product quality and expectations, play a dominant role in final review scores.

---

## 🛠 Data Pipeline & Engineering

### 1. Rigorous Data Auditing
* **Translation Recovery:** Identified **623 products** lacking English translations.
* **Methodology:** Programmatic audits revealed 610 true blanks and **13 valid Portuguese categories** (e.g., `pc_gamer`, `portateis_cozinha`) missing from the translation dictionary. These were manually recovered to maintain data integrity.

### 2. Mathematical Outlier Removal
* **Approach:** Utilized the **Interquartile Range (IQR) method** to identify delivery delay outliers rather than using arbitrary caps.
* **Result:** Cleaned the dataset from 96,359 to **91,546 rows**, ensuring the model was trained on representative logistics data and remained robust against data-entry anomalies.

---

## 📊 Key Findings from Exploratory Data Analysis (EDA)
* **Logistics Efficiency:** Over **75% of orders arrive early** (Third Quartile is below zero), indicating that Olist employs a conservative estimation strategy.
* **The "Chaos Zone":** 1-star reviews exhibit significantly higher variance in both price and delivery delay compared to 5-star reviews, indicating high unpredictability in dissatisfied customer experiences.
* **Statistical Verdict:** Kruskal-Wallis tests confirmed a highly significant relationship ($p < 2.2e-16$) between delay and scores, though the effect size is small ($\epsilon^2 \approx 0.015$), explaining only ~1.5% of score variance.

---

## 🤖 Machine Learning: Random Forest (Ranger)
I trained a **Random Forest** classifier using the `ranger` package to predict review scores based on delivery delay, product price, freight cost, and category.

### Model Performance
* **Final Accuracy:** **58.62%**.
* **The "Middle-Tier" Constraint:** **Achieved 58.62% classification accuracy, highlighting that logistics data serves as a critical baseline but suggests product quality as the primary unobserved driver of sentiment**.
* **Analysis:** The model successfully identifies extreme 1-star and 5-star sentiments but struggles with 2-4 star ratings. This confirms that logistics and price data alone are insufficient to distinguish between mediocre and good experiences.

### Feature Importance (The "Drivers")
1.  **`delivery_delay`**: The #1 predictor of satisfaction identified by the model.
2.  **`total_freight`**: Interestingly more influential than product price, suggesting high customer sensitivity toward shipping costs.
3.  **`total_price`**: Secondary to logistics performance in driving sentiment.
4.  **`category_english`**: The least influential factor, suggesting satisfaction drivers are largely universal across product types.

---

## 💡 Business Recommendations
* **Optimize Freight:** Since `total_freight` is a major driver of dissatisfaction, Olist should explore subsidized shipping or "free shipping" thresholds to improve scores.
* **Target the "Late" Threshold:** Because most packages arrive early, any delay is perceived as a significant failure. Improving the accuracy of the "Estimated Delivery Date" could manage customer expectations more effectively.

---

## 🚀 Future Work & Potential Improvements
While this project established a strong baseline for logistics-driven sentiment, several avenues exist to improve predictive power:

### 1. Advanced Modeling & Balancing
* **Gradient Boosting (XGBoost/LightGBM):** Future iterations could utilize boosting models to better capture the "hard-to-predict" 2-4 star reviews.
* **Class Imbalance:** Experimenting with **SMOTE** (Synthetic Minority Over-sampling Technique) to improve the model's sensitivity to non-5-star reviews.

### 2. Natural Language Processing (NLP)
* **Sentiment Analysis:** Incorporating the actual text of customer reviews (using BERT or VADER) would likely bridge the accuracy gap by capturing qualitative complaints regarding product quality or seller communication.

### 3. Feature Engineering
* **Seller Reputation:** Integrating seller-specific metrics (e.g., historical average rating) could explain why similar deliveries result in different scores.

## 📂 Data Source
The dataset used in this analysis is the **Brazilian E-Commerce Public Dataset by Olist**, available on Kaggle. 
* **Download Link:** [Kaggle - Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
* **Instructions:** To run the analysis script, download the files from the link above and place them in the project root directory.
