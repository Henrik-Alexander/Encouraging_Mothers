##############################################################
#
#     Encouraging Mothers: The dynamic interplay of childcare quality and availability on the transition to employment after first-childbirth
#     Henrik-Alexander Schubert
#########################################################################

  # last edited on: 16.06.2022
  # last edited by: Henrik-Alexander Schubert
  

#### Preperations ===============================

  # Load the packages
  library(tidyverse)
  library(haven)
  library(survival)
  library(broom)
  library(svglite)
  library(patchwork)

  # load the dataset
  d <- haven::read_dta("ANALYSIS.dta")
  
  
  
  # set theme
  theme_set(theme_bw(base_size = 20, base_family = "serif"))
  theme_update(
    panel.grid.major.y = element_line(colour = "grey90"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    legend.background = element_rect(fill = "white", colour = "grey80"),
    legend.title = element_text(face = "bold"),
    axis.title.x = element_text(face = "bold", size = 16),
    axis.title.y = element_text(face = "bold", size = 16),
    plot.title.position = "plot"
  )
  


#### Kaplan-Meier Survival curve ====================
  
  
  # calculate the kaplan-meier survival curve
  KM <- survival::survfit(Surv(`_t0`, `_t`, `_d`) ~ 1, id = id, data = d)
  
  # transform to tidy data
  KM <- tidy(KM) %>% ggplot(aes(x = time, y = estimate, ymin = conf.low, ymax = conf.high)) +
    geom_line(colour = "#066E6E", size = 1.5) +
    geom_ribbon(alpha = 0.3, fill = "#066E6E") +
    xlab("Months since first childbirth") +
    ylab("Share out of unemployed") +
    scale_y_continuous(limits = c(0, 1) , expand = c(0, 0)) +
    scale_x_continuous(expand = c(0, 0.01))

  # save the plot
  ggsave(KM, filename = "Output/km_return.svg")
  

#### Policy plot ===================================
  
  
  # load the data
  dta <- haven::read_dta("context-data.dta")
  
  # plot childcare quality  
  b <- ggplot(dta, aes(x = beginning_year, y = 10/childtoadultratio, group = beginning_year)) +
    geom_hline(yintercept = 3, size = 1.3, colour = "firebrick") +
    geom_boxplot(colour = "black", fill = "#066E6E", width = 0.5) +
    ylab("Adult-to-child ratio") +
    xlab("Year") +
    scale_y_continuous(expand = c(0, 0.1), n.breaks = 8) +
    scale_x_continuous(expand = c(0, 0.2), n.breaks = 10) +
    theme(axis.text.x = element_text( hjust = 1, angle = 45)) +
    ggtitle("B) Childcare quality")
  

  # plot childcare quality  
  a <- ggplot(dta, aes(x = beginning_year, y = enrollment, group = beginning_year)) +
    geom_boxplot(colour = "black", fill = "#066E6E", width = 0.5) +
    ylab("Childcare availability") +
    xlab("Year") + 
    ggtitle("A) Childcare availability") +
    theme(axis.text.x = element_text( hjust = 1, angle = 45)) +
    scale_x_continuous(expand = c(0, 0.2), n.breaks = 10)

  # assemble the plots
  c <- a / b + plot_annotation(caption = "Sources: Destatis/Statistisches Bundesamt.")
  
  
  # save the plot
  ggsave(c, filename = "Output/childcare_reform.svg")
  
  
### plot margins =============================0
  
  # load the predicted hazards
  data <- read_dta("predicted_hazards.dta")

  #  clean the names
  names(data) <- names(data) %>% str_remove("_")
  
  # make the category a factor variable
  data$at <- factor(data$at, labels = c("20", "40", "60"))
  
  # add an extra spell for the end
  data <- data %>% filter(m1 == 24) %>% mutate(m1 = 36) %>% bind_rows(data, .) %>% arrange(at, m1)
  
  # create end spell
  data <- mutate(data, end = m1 + 12)
  
  # plot the data
  pred <-  ggplot(data, aes(x = m1, y = margin, group = at, alpha = at)) +
    geom_step(size = 2, colour = "#066E6E") +
    ylab("Predicted hazard") +
    xlab("Time") +
    scale_x_continuous(limits = c(0, 36), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 0.15), expand = c(0, 0), n.breaks = 6) +
    scale_alpha_manual(name = "Availability:", values = c("20" = 0.4, "40" = 0.7, "60" = 1)) +
    guides(alpha = "none") +
    annotate(geom = "text", x = 5, y = 0.055, label = "Availability = 60", size = 6, family = "serif", colour = "#066E6E") +
    annotate(geom = "text", x = 5, y = 0.03, label = "Availability = 40", size = 6, family = "serif", colour = "#066E6E") +
    annotate(geom = "text", x = 5, y = 0.01, label = "Availability = 20", size = 6, family = "serif", colour = "#066E6E") +
    ggtitle("Prediction: time-varying effect of childcare availability")

  # save the plot
  ggsave(pred, filename = "Output/pred.svg")
  
  
  # plot the data
  pred2 <- ggplot(data, aes(x = m1, y = margin, group = at, colour = at)) +
    geom_step(size = 2) +
    ylab("Predicted hazard") +
    xlab("Time") +
    scale_x_continuous(limits = c(0, 36), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 0.15), expand = c(0, 0), n.breaks = 6) +
    scale_colour_discrete(name = "Availability:") +
    theme(legend.position = "bottom") +
    ggtitle("Prediction: time-varying effect of childcare availability")
  
  # save the plot
  ggsave(pred2, filename = "Output/pred1.svg")
  
  