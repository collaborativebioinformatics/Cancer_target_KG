library(dplyr)
library(ggplot2)

#data load in
metadata<-read.csv("./coad_metadata.csv")

#remove odd/no data cols
metadata <- metadata[, -which(names(metadata) %in% 
                                c("...1", "clinical_stage", "histological_grade",
                                 "menopause_status", "Redaction", "margin_status",
                                 "residual_tumor","new_tumor_event_site","new_tumor_event_site",
                                 "cause_of_death"))]

#lollipop plot
metadata$vital_status<- as.factor(metadata$vital_status)

#combine last contact and death days cols
df1 %>%
  mutate(Vote = coalesce(DidVote, WouldVote))

#data frame used for lollipop plot specifically
meta_lollipop<-data.frame(
  Patients=metadata$bcr_patient_barcode,
  Time=metadata$death_days_to,
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
  scale_color_manual(values = c("#6CE5E8", "#31356E"))
#remove data frame after
rm(brain_lollipop)