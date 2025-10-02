library(dplyr)
library(ggplot2)
library(survminer)
library(ggpubr)
library(ggsurvfit)

#data load in-- make sure to set to proper dir
metadata<-read.csv("./coad_metadata.csv")

#lollipop plot
metadata$vital_status<- as.factor(metadata$vital_status)

#data frame used for lollipop plot specifically
meta_lollipop<-data.frame(
  Patients=metadata$bcr_patient_barcode,
  Time=metadata$OS.time,
  Status=metadata$vital_status
)

#only plot those with time values
meta_lollipop<- meta_lollipop[-c(which(is.na(meta_lollipop$Time))),]

meta_lollipop %>%
  arrange(desc(Time)) %>%    # First sort by val. This sorts the dataframe but NOT the factor levels
  mutate(Patients=factor(Patients, levels=Patients)) %>%
  ggplot(aes(x=Patients, y=Time, color=meta_lollipop$Status)) +
  geom_segment( aes(x=Patients, xend=Patients, y=0, yend=Time), color="#41B8D5") +
  geom_point(size=3.5) +
  geom_point(aes(color=meta_lollipop$Status))+
  theme_light() +
  ggtitle("Time to Event for Each Patient") +
  theme(
    panel.grid.major.y = element_blank(),
    panel.border = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.x = element_blank(),
    legend.title = element_text(hjust = 0.5, size = 13),
    legend.text = element_text(size = 13),
    plot.background = element_rect(fill = "#F2F4F5"),
    legend.background = element_rect(fill = "#F2F4F5"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "#F2F4F5"),
    plot.title = element_text(hjust = 0.5, size = 18),
    axis.title.x = element_text(size=13),
    axis.title.y = element_text(size = 13)
  )+
  ylab("Time (in days)")+
  labs(
    color="Status"
  )+
  scale_color_manual(labels = c("Censored", "Dead"), values = c("#6CE5E8", "#31356E"))
#remove data frame after
rm(meta_lollipop)

#--- sex distribution ----
meta_tibble<-as_tibble(metadata)
num.gender <- matrix(c(nrow(meta_tibble[meta_tibble$gender=='MALE',]), nrow(meta_tibble[meta_tibble$gender=='FEMALE',])),ncol=2,nrow=1,byrow = T)
row.names(num.gender) <- c("Amount of Patients")
colnames(num.gender) <- c("Male", "Female")
num.gender <- data.frame(
  gender=colnames(num.gender),  
  patients=c(num.gender[1], num.gender[2])
)

ggplot(num.gender, aes(x=gender, y=patients, fill=gender)) + 
  geom_bar(stat = "identity")+
  scale_fill_manual(values=c("#6CE5E8", "#2D8BBA"))+
  labs(fill = "Gender")+
  ylab("Patients")+
  xlab("Gender")+
  ggtitle("Amount of Patients of each Gender")+
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        plot.background = element_rect(fill = "#F2F4F5"),
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#F2F4F5"),
        legend.background = element_rect(fill = "#F2F4F5"),
        legend.title = element_text(hjust = 0.5, size = 13),
        axis.title.x = element_text(size = 13),
        axis.title.y = element_text(size = 13),
        legend.text = element_text(size = 13),
        axis.text = element_text(size = 12))
rm(num.gender)

#vital_status vs. gender -- NOT SIGNIFICANT
#set up contingency table
num.m.alive <- nrow(meta_tibble[meta_tibble$gender=="MALE" & meta_tibble$vital_status=="Alive",])
num.f.alive <- nrow(meta_tibble[meta_tibble$gender=="FEMALE" & meta_tibble$vital_status=="Alive",])
num.m.dead <- nrow(meta_tibble[meta_tibble$gender=="MALE" & meta_tibble$vital_status=="Dead",])
num.f.dead <- nrow(meta_tibble[meta_tibble$gender=="FEMALE" & meta_tibble$vital_status=="Dead",])
vit.gen.contigencytbl <- matrix(c(num.m.alive, num.f.alive,
                                  num.m.dead, num.f.dead),ncol=2,nrow=2,byrow = T)
row.names(vit.gen.contigencytbl) <- c("Alive","Dead")
colnames(vit.gen.contigencytbl) <- c("Male", "Female")
#perform chi squared test
chi_test <- chisq.test(vit.gen.contigencytbl, correct = F)
chi_test
chi_test$observed
chi_test$expected
#perform fisher exact test
fisher <- fisher.test(vit.gen.contigencytbl)
fisher
rm(chi_test, fisher, vit.gen.contigencytbl, num.m.alive, num.m.dead,
   num.f.alive, num.f.dead)

#kaplan meier
survfit2(Surv(OS.time, as.numeric(vital_status))~gender,data=meta_tibble) |>
  ggsurvfit(linewidth = 1) +
  add_censor_mark()+
  add_confidence_interval("lines") + # add confidence interval
  add_quantile(y_value = 0.5, color = "gray50", linewidth = 0.75)+  # Specify median survival
  labs(title = "Survival Probability by Gender",
       x="Time (Days)",
       color="Gender")+
  add_pvalue("annotation") +  
  scale_color_manual(values = c("#6CE5E8", "#31356E"))+
  scale_fill_manual(values = c("#6CE5E8", "#31356E")) +
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        plot.background = element_rect(fill = "#F2F4F5"),
        panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#F2F4F5"),
        legend.background = element_rect(fill = "#F2F4F5"),
        legend.title = element_text(hjust = 0.5, size = 13),
        legend.position = "right",
        axis.title = element_text(size = 13),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 13))

#--- binary age ----
num.old <- matrix(c(nrow(meta_tibble[meta_tibble$older_than_50==1,]), nrow(meta_tibble[meta_tibble$older_than_50==0,])),ncol=2,nrow=1,byrow = T)
row.names(num.old) <- c("Amount of Patients")
colnames(num.old) <- c("Older than 50", "50 or Younger")
num.old <- data.frame(
  older_than_50=colnames(num.old),  
  patients=c(num.old[1], num.old[2])
)

ggplot(num.old, aes(x=older_than_50, y=patients, fill=older_than_50)) + 
  geom_bar(stat = "identity")+
  scale_fill_manual(values=c("#6CE5E8", "#2D8BBA"))+
  labs(fill = "Older than 50")+
  ylab("Patients")+
  xlab("Older than 50")+
  ggtitle("Amount of Patients of each Age Grpup")+
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        plot.background = element_rect(fill = "#F2F4F5"),
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#F2F4F5"),
        legend.background = element_rect(fill = "#F2F4F5"),
        legend.title = element_text(hjust = 0.5, size = 13),
        axis.title.x = element_text(size = 13),
        axis.title.y = element_text(size = 13),
        legend.text = element_text(size = 13),
        axis.text = element_text(size = 12))
rm(num.old)

#vital_status vs. age group -- NOT SIGNIFICANT
#set up contingency table
num.o.alive <- nrow(meta_tibble[meta_tibble$older_than_50==1 & meta_tibble$vital_status=="Alive",])
num.y.alive <- nrow(meta_tibble[meta_tibble$older_than_50==0 & meta_tibble$vital_status=="Alive",])
num.o.dead <- nrow(meta_tibble[meta_tibble$older_than_50==1 & meta_tibble$vital_status=="Dead",])
num.y.dead <- nrow(meta_tibble[meta_tibble$older_than_50==0 & meta_tibble$vital_status=="Dead",])
vit.age.contigencytbl <- matrix(c(num.o.alive, num.y.alive,
                                  num.o.dead, num.y.dead),ncol=2,nrow=2,byrow = T)
row.names(vit.age.contigencytbl) <- c("Alive","Dead")
colnames(vit.age.contigencytbl) <- c("Older_than_50", "50_or_younger")
#perform chi squared test
chi_test <- chisq.test(vit.age.contigencytbl, correct = F)
chi_test
chi_test$observed
chi_test$expected
#perform fisher exact test
fisher <- fisher.test(vit.age.contigencytbl)
fisher
rm(chi_test, fisher, vit.age.contigencytbl, num.o.alive, num.o.dead,
   num.y.alive, num.y.dead)

#kaplan Meier
survfit2(Surv(OS.time, as.numeric(vital_status))~older_than_50,data=meta_tibble) |>
  ggsurvfit(linewidth = 1) +
  add_censor_mark() +
  add_confidence_interval("lines") + # add confidence interval
  add_quantile(y_value = 0.5, color = "gray50", linewidth = 0.75)+  # Specify median survival
  labs(title = "Survival Probability by Age Group",
       x="Time (Days)",
       color="Age")+
  add_pvalue("annotation") +  
  scale_color_manual(values = c("#6CE5E8", "#31356E"))+
  scale_fill_manual(values = c("#6CE5E8", "#31356E")) +
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        plot.background = element_rect(fill = "#F2F4F5"),
        panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#F2F4F5"),
        legend.background = element_rect(fill = "#F2F4F5"),
        legend.title = element_text(hjust = 0.5, size = 13),
        legend.position = "right",
        axis.title = element_text(size = 13),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 13))

#--- basic Kaplan-Meier ----
#not taking into account any covariates
fit_KM <- survfit(Surv(OS.time, as.numeric(vital_status)) ~ 1, data = meta_tibble)
fit_KM
ggsurvfit(fit_KM, linewidth = 1, color = "#31356E") +
  add_confidence_interval(fill = "#6CE5E8") + # add confidence interval
  add_risktable()+ # Add risk table
  add_quantile(y_value = 0.5, color = "gray50", linewidth = 0.75)+  # Specify median survival
  labs(title = "Kaplan-Meier Curve for Stomach Cancer Survival",
       x="Time (Days)")+
  scale_x_continuous(breaks = seq(0,90,by=10))+
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        plot.background = element_rect(fill = "#F2F4F5"),
        panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#F2F4F5"),
        legend.background = element_rect(fill = "#F2F4F5"),
        legend.title = element_text(hjust = 0.5, size = 13),
        legend.position = "right",
        axis.title = element_text(size = 13),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 13))


#--- Histological Type ----
meta_tibble_hist_type <- meta_tibble[which(meta_tibble$histological_type != "[Not Available]" & meta_tibble$histological_type != "[Discrepancy]"),]
survfit2(Surv(OS.time, as.numeric(vital_status))~histological_type,data=meta_tibble_hist_type) |>
  ggsurvfit(linewidth = 1) +
  add_censor_mark() +
  add_confidence_interval("lines") + # add confidence interval
  add_quantile(y_value = 0.5, color = "gray50", linewidth = 0.75)+  # Specify median survival
  labs(title = "Survival Probability by Histological Type",
       x="Time (Days)",
       color="Type")+
  add_pvalue("annotation") +  
  scale_color_manual(values = c("#6CE5E8", "#31356E"))+
  scale_fill_manual(values = c("#6CE5E8", "#31356E")) +
  theme(plot.title = element_text(hjust = 0.5, size = 18), 
        plot.background = element_rect(fill = "#F2F4F5"),
        panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#F2F4F5"),
        legend.background = element_rect(fill = "#F2F4F5"),
        legend.title = element_text(hjust = 0.5, size = 13),
        legend.position = "right",
        axis.title = element_text(size = 13),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 13))
