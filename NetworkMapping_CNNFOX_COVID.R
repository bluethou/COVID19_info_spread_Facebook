library(tidyverse)

################################################
# This script is make nodes and links files for graph representation.
# The final nodes and links files can be loaded on Gephi.
# You should have 'cnn_posts_list', and 'fox_posts_list'.
################################################

make_nodes <- function(input){
  df <- input %>% select(accountID, account.name, group,account.verified)
  ID_label_count = df %>% 
    group_by(account.name) %>% 
    count() %>% 
    inner_join(df, by = ("Label"="account.name")) %>%  
    distinct()
  colnames(ID_label_count) = c("Label","Appearance", "ID", "Type", "Verified")
  ID_label_count = ID_label_count %>%
    relocate(c("ID","Label","Appearance","Type")) %>%
    arrange(desc(Appearance))
  ID_label_count$ID = as.character(ID_label_count$ID)
  ID_label_count = ID_label_count %>% mutate(Verified = ifelse(Verified, "verified", "not_verified"))
  # ID_label_count$Verified = as.character(ID_label_count$Verified)
  
  temp_df = data.frame(input$link)
  temp_df = temp_df %>% 
    group_by(input.link) %>% 
    count()
  temp_df$ID = temp_df$input.link
  colnames(temp_df) = c("Label", "Appearance","ID")
  temp_df = temp_df %>% relocate(c("ID","Label","Appearance"))
  temp_df$Type = "Link"
  temp_df$Verified = "Link"
  
  rbind(ID_label_count,temp_df)
}

make_links <- function(input){
  df <- input %>% 
    select(accountID,link) %>% 
    group_by(accountID,link) %>% 
    count() %>% 
    arrange(desc(n))
  colnames(df) <- c("Source", "Target","Weight")
  df
}

#####

nodes_brand <- make_nodes(cnn_posts_list) %>% mutate(Stand = "CNN")
nodes_nobrand <- make_nodes(fox_posts_list) %>% mutate(Stand = "Fox_News")
both_sides_ID <- intersect(nodes_brand$ID, nodes_nobrand$ID)

both_sides_from_supp <- nodes_brand %>% filter(ID %in% (both_sides_ID)) 
both_sides_from_hate <- nodes_nobrand %>% filter(ID %in% (both_sides_ID)) 
both_sides <- inner_join(both_sides_from_supp,both_sides_from_hate, by=("ID"="ID")) %>% 
  mutate(Appearance = Appearance.x + Appearance.y) %>% 
  select(ID, Label.x, Appearance, Type.x, Stand.x, Verified.x) %>% 
  rename("Label"="Label.x", "Type"="Type.x","Stand" = "Stand.x", "Verified"="Verified.x")
both_sides$Stand = "both"

# # Find Daily Wire's adds
# DWads = branded %>% filter(`Sponsor Name`=="Daily Wire") %>% select(Link)
# nodes_brand = nodes_brand %>% mutate(DW = ID %in% DWads$Link)
# nodes_nobrand$DW = NA

nodes <- rbind(nodes_brand, nodes_nobrand)
one_side <- nodes %>% filter((ID %in% both_sides_ID)==FALSE)
one_side
final_nodes <- rbind(one_side,both_sides)

links_hate = make_links(cnn_posts_list) # change input variable
links_supp = make_links(fox_posts_list)

links <- rbind(links_hate, links_supp)

##########
COVID_CNN <- read_csv("CNN_COVID_2020.csv")
COVID_FOX <- read_csv("FOX_COVID_2020.csv")
poli_CNN <- read_csv("CNN_politics_2020.csv")
poli_FOX <- read_csv("FOX_politics_2020.csv")

COVID_neighbors <- links %>% filter(Target %in% append(COVID_CNN$Link, COVID_FOX$Link))
politics_neighbors <- links %>% filter(Target %in% append(poli_CNN$Link, poli_FOX$Link))

final_nodes <- rbind(one_side,both_sides) %>% 
  mutate(COVID = ifelse(ID %in% 
                          append(COVID_neighbors$Source, COVID_neighbors$Target), TRUE, FALSE)) %>% 
  mutate(Politics = ifelse(ID %in% 
                          append(politics_neighbors$Source, politics_neighbors$Target), TRUE, FALSE))

covidnodes <- final_nodes %>% filter(COVID==TRUE) 
table(covidnodes$Stand)

polinodes <- final_nodes %>% filter(Politics==TRUE)
table(polinodes$Stand)

final_nodes %>% filter(COVID==TRUE) %>% filter(Politics==TRUE)

##########
write_csv(final_nodes, "csvfiles/nodes.csv")
write_csv(links, "csvfiles/links.csv")