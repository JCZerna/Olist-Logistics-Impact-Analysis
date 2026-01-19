################################################################################
# PROJECT: Olist Customer Satisfaction Analysis
# GOAL: Predict Review Scores using Logistics and Price Data
# AUTHOR: [JCZerna]
################################################################################

##### 1. Libraries & Data Loading ####
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, ggthemes, car, rstatix, ranger)

# Load raw Olist datasets
orders   <- read_csv("olist_orders_dataset.csv")
reviews  <- read_csv("olist_order_reviews_dataset.csv")
items    <- read_csv("olist_order_items_dataset.csv")
products <- read_csv("olist_products_dataset.csv")
trans    <- read_csv("product_category_name_translation.csv")

##### 2. Pre-Join Preparation ####
# Recovery: 610 missing categories labeled as "unknown"

products_cleaned <- products %>%
    mutate(product_category_name = replace_na(product_category_name, 
                                              "unknown"))

# Items: Summarize to ensure exactly ONE row per order_id for a clean join

items_summarized <- items %>%
    group_by(order_id) %>%
    summarise(
        total_price = sum(price),
        total_freight = sum(freight_value),
        product_id = first(product_id), 
        total_items = n())

##### 3. The Master Join ####

master_df <- reviews %>%
    select(order_id, review_score) %>%
    inner_join(orders, by = "order_id") %>%
    inner_join(items_summarized, by = "order_id") %>%
    inner_join(products_cleaned, by = "product_id") %>%
    left_join(trans, by = "product_category_name") %>%
    mutate(
        # Handle English translation and NA recovery
        category_english = replace_na(product_category_name_english, "unknown"),
        review_score = as.factor(review_score),
        # TARGET VARIABLE: Delivery Delay (Actual vs Estimated)
        delivery_delay = as.numeric(difftime(order_delivered_customer_date, 
                                             order_estimated_delivery_date, 
                                             units = "days"))) %>% 
    filter(!is.na(delivery_delay))

##### 4. Manual Translation Recovery ####
# Fix for 13 specific rows identified during programmatic audit

master_df <- master_df %>%
    mutate(category_english = case_when(
        product_category_name == "pc_gamer" ~ "pc_gamer",
        product_category_name == "portateis_cozinha_e_preparadores_de_alimentos" ~ "kitchen_portables",
        TRUE ~ category_english))

##### 5. Mathematical Outlier Removal (IQR Method) ####

Q1 <- quantile(master_df$delivery_delay, 0.25)
Q3 <- quantile(master_df$delivery_delay, 0.75)
IQR_value <- Q3 - Q1

# Define statistical fences

lower_bound <- Q1 - 1.5 * IQR_value
upper_bound <- Q3 + 1.5 * IQR_value

# Filtered from 96,359 to 91,546 rows

master_df <- master_df %>%
    filter(delivery_delay >= lower_bound & delivery_delay <= upper_bound)

##### 6. EDA: Logistics vs. Sentiment ####
ggplot(master_df, aes(x = review_score, y = delivery_delay, 
                      fill = review_score)) + 
    geom_boxplot(outlier.shape = NA) + 
    coord_cartesian(ylim = c(-20, 25)) + 
    labs(
        title = "The Logistics Effect: How Delays Drive Reviews",
        subtitle = "Calculated using 91,546 cleaned observations",
        x = "Customer Review Score (1-5 Stars)",
        y = "Days Relative to Estimated Delivery") + 
    theme_minimal() +
    scale_fill_brewer(palette = "RdYlGn") +
    theme(legend.position = "none", 
          plot.title = element_text(face = "bold"))

##### 7. Statistical Testing & Assumptions ####
# ANOVA

logistics_anova <- aov(delivery_delay ~ review_score, data = master_df)
summary(logistics_anova)

# Assumption Checks

car::leveneTest(delivery_delay ~ review_score, data = master_df) # Equal Variance
plot(logistics_anova, which = 2) # Normality (Q-Q Plot)

##### 8. Robust & Non-Parametric Testing ####
# Welch's ANOVA (Robust to unequal variance)

welch_result <- master_df %>% welch_anova_test(delivery_delay ~ review_score)

# Kruskal-Wallis & Effect Size (Non-parametric 'Ace')

kruskal_result <- master_df %>% kruskal_test(delivery_delay ~ review_score)
effect_size <- master_df %>% kruskal_effsize(delivery_delay ~ review_score)

print(kruskal_result)
print(effect_size) # Expected ~0.015 (Small Magnitude)

##### 9. Feature Engineering & Modeling ####

rf_data <- master_df %>%
    select(review_score, delivery_delay, total_price, 
           total_freight, category_english) %>% 
    mutate(category_english = as.factor(category_english)) %>% 
    drop_na()

# Data Splitting (80/20)

set.seed(123)
train_index <- sample(1:nrow(rf_data), 0.8 * nrow(rf_data))
train_set <- rf_data[train_index, ]
test_set  <- rf_data[-train_index, ]

# Training Ranger (Random Forest)

rf_model <- ranger(review_score ~ ., 
                   data = train_set, 
                   importance = "permutation",
                   num.trees = 500)
print(rf_model)

##### 10. Variable Importance & Evaluation ####
# Plot Importance

importance_df <- data.frame(
    Feature = names(rf_model$variable.importance),
    Importance = rf_model$variable.importance)

ggplot(importance_df, aes(x = reorder(Feature, Importance), 
                          y = Importance, fill = Importance)) +
    geom_col() + coord_flip() +
    scale_fill_gradient(low = "skyblue", high = "darkblue") +
    labs(title = "What Drives Customer Reviews at Olist?",
         subtitle = "Feature Importance (Permutation)",
         x = "Predictor Variables", y = "Importance") + 
    theme_minimal() + theme(legend.position = "none")

# Evaluation: Confusion Matrix

predictions <- predict(rf_model, data = test_set)$predictions
conf_matrix <- table(Predicted = predictions, Actual = test_set$review_score)
print(conf_matrix)

# Accuracy Calculation

accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)
cat("Final Test Accuracy:", round(accuracy * 100, 2), "%\n")

################################ END OF SCRIPT ################################