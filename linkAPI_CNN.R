library(httr)
library(tidyverse)
library(lubridate)
library(jsonlite)

CNN <- read_csv("csvfiles/CNN_2020.csv") # load CNN most interacted posts
urls =CNN$Link[1:100] # Top 100's links

##########################################
# Get posts sharing the URLs by the link API
##########################################
site_url = "https://api.crowdtangle.com/links"
auth_key = "I2RzFgrfvPFWruFXRDrswizIDz2raQZtZP9yCmVt"
list_id = 1472769
# searchTerm = "COVID-19"
sortBy = "total_interactions"
count = 1000
startDate = "2020-01-01"
get_link <- function(link="https://www.pfizer.com/news/press-release/press-release-detail/pfizer-and-biontech-announce-vaccine-candidate-against"){
  query_str = paste(site_url, "?token=", auth_key, "&link=",link, "&startDate=",startDate,"&count=", count, "&sortBy=",sortBy,sep = "")
  resp = GET(query_str,add_headers("Authorization"=auth_key))
  resp
  resp.str = as.character(resp)
  d= fromJSON(resp.str)
  d$result$posts
}

##########################################
# Data processisng function
##########################################
posts_to_sharing_info = function(posts_input){
  posts_input$veri = posts_input$account$verified
  posts_input$accountID = posts_input$account$id
  posts_input$date = posts_input$date %>% lubridate::as_datetime()  %>% round_date("hour")
  posts_input$group = posts_input$account$accountType
  posts_input = flatten(posts_input)
  posts_input$total_interaction_except_shares = (posts_input) %>% select(-statistics.actual.shareCount) %>% 
    select(starts_with("statistics.actual")) %>% replace(is.na(.), 0) %>% 
    mutate(total_interaction = rowSums(.)) %>% 
    select(total_interaction) 
  # posts_input  
  sharing_info = posts_input %>% 
    select(accountID,
           platformId, 
           account.name, 
           date, 
           total_interaction_except_shares, 
           subscriberCount, 
           statistics.actual.shareCount, 
           account.verified, 
           group, 
           link,
           statistics.actual.loveCount,
           statistics.actual.wowCount,statistics.actual.hahaCount,statistics.actual.sadCount,
           statistics.actual.angryCount,statistics.actual.careCount,
           message) %>% 
    arrange(date)
  sharing_info
}

##########################################
# Crawling all posts sharing the 100 most interacted posts, and processing
##########################################
cnn_posts_list = data.frame()
for (url in urls) {
  print(url)
  temp_post = get_link(url) 
  if (is.null(temp_post) | (length(temp_post)==0)) {
    next
  }
  manipulated_posts = posts_to_sharing_info(temp_post)
  cnn_posts_list = rbind(cnn_posts_list, manipulated_posts)
  print("found posts")
  Sys.sleep(30)
}

cnn_sharing_info_topic2 = cnn_posts_list
sharing_info=cnn_sharing_info_topic2
