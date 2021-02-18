library(httr)
library(tidyverse)
library(jsonlite)
library(zoo)
library(lubridate)
library(imputeTS)
library(rrr)
library(corrplot)

####################################################
# Warning: This script crawls data for prediction modeling, which may take less than 2 days in total
####################################################

####################################################
# searchAPI: search Facebook postsby query
####################################################
auth_key = "I2RzFgrfvPFWruFXRDrswizIDz2raQZtZP9yCmVt"
searchAPI <- function(searchTerm, count = 100, sortBy = "total_interactions", startDate = "2020-01-01", endDate="2021-01-01"){
  site_url = "https://api.crowdtangle.com/posts/search"
  brandedContent = "as_publisher" # as_marketer
  
  query_str = paste(site_url, "?token=", auth_key,
                    "&searchTerm=",searchTerm, 
                    "&count=", count,
                    # "&sortBy=",sortBy,
                    "&startDate=", startDate,
                    "&endDate=", endDate,
                    # "&brandedContent=", brandedContent,
                    "&language=", "EN",
                    sep = "")
  query_str
  resp = GET(query_str,add_headers("Authorization"=auth_key))
  resp.str = as.character(resp)
  d= fromJSON(resp.str)
  result_posts=data.frame()
  if(length(d$result$posts) >0){
    result_posts = flatten(d$result$posts)
  }
  as_tibble(result_posts)
}

####################################################
# get_post: function to a specific post with platform ID
####################################################
get_post <- function(platformid, include_history=TRUE){
  query_str = paste("https://api.crowdtangle.com/post/",platformid,"?token=",auth_key,"&includeHistory=",include_history,sep = "")
  resp = GET(query_str,add_headers("Authorization"=auth_key))
  resp.str = as.character(resp)
  d= fromJSON(resp.str)
  d$result$posts
}

####################################################
# Run searchAPI to acquire monthly data
####################################################
get_monthly_search <- function(searchTerm){
  date_list = seq(ymd('2020-01-01'),ymd('2021-01-01'), by = '1 month')
  df = data.frame()
  for (i in 1:(length(date_list)-1)) {
    print(i)
    temp<- searchAPI(searchTerm, startDate = date_list[i], endDate = date_list[i+1])
    if(length(temp)==0){
      next
    } else{
      temp = temp %>% filter(!is.na(account.accountType))
    }
    temp = temp %>% select("platformId","type","message","subscriberCount", "score",
                           "statistics.actual.shareCount","statistics.actual.commentCount",
                           "statistics.actual.loveCount", "statistics.actual.wowCount",      
                           "statistics.actual.hahaCount", "statistics.actual.sadCount",
                           "statistics.actual.angryCount",
                           "statistics.actual.careCount", 
                           "account.accountType","account.verified")
    df = rbind(df,temp)
    Sys.sleep(10)
  }
  df
}

####################################################
# Crawl monthly posts for each topic 
####################################################
mask <- get_monthly_search("COVID%20AND%20mask")
lockdown <- get_monthly_search("COVID%20AND%20lockdown")
vaccine <- get_monthly_search("COVID%20AND%vaccine")

trump <- get_monthly_search("COVID%20AND%20trump")
biden <- get_monthly_search("COVID%20AND%20biden")
jesus <- get_monthly_search("COVID%20AND%jesus")

####################################################
# For every post, crawl its time-series history
# length: the number of posts to crawl 
# imputation: if TRUE, it linearly imputes data until inputed_timestep
# inputed_timestep: maximum timestep to impute
####################################################
get_posts_history <- function(item, length=10, imputation=FALSE, inputed_timestep=13){
  platformId_vector = item$platformId[1:length]
  df_all = tibble()
  
  for (i in 1:length(platformId_vector)) {
    possibleError <- tryCatch(
      {print(i)
        pid = platformId_vector[i]
        post <- get_post(pid)
        df <- post$history %>% as.data.frame()
        # imputation
        if(imputation==TRUE){
          if(nrow(df)>inputed_timestep){
            df = tail(df,inputed_timestep)
          }
          impute <- left_join(tibble(timestep=1:inputed_timestep),df,by='timestep') %>% flatten() %>% select(-date)
          impute = na.approx(impute) %>% na_interpolation(option ="linear")
          df = as.data.frame(impute)
        }
        df$pid = pid
        df$url = post$postUrl
        df$message = post$message
        # df$title = post$title
        df$accountType = post$account$accountType
        df$verified = post$account$verified
        df$subscriberCount = post$account$subscriberCount
        df$account.name = post$account$name
        # print(df$account.name)
        df_all = bind_rows(df_all, df)
      },
      error=function(e) e
    )
    
    if(inherits(possibleError, "error")) next
    
    Sys.sleep(10)
  }
  
  df_all
}

####################################################
# sort the crawled data by share count
####################################################
mask <- mask %>% arrange(desc(statistics.actual.shareCount))
lockdown <- lockdown %>% arrange(desc(statistics.actual.shareCount))
vaccine <- vaccine%>% arrange(desc(statistics.actual.shareCount))

trump <- trump %>% arrange(desc(statistics.actual.shareCount))
biden <- biden %>% arrange(desc(statistics.actual.shareCount))
jesus <- jesus%>% arrange(desc(statistics.actual.shareCount))

####################################################
# crawl and impute data at the sametime
####################################################
len = 1000
imputed_mask <- get_posts_history(mask[1:len,], length=len, imputation = TRUE, inputed_timestep=47)
# write_csv(imputed_mask, "csvfiles/imputed_mask.csv")
imputed_lockdown <- get_posts_history(lockdown[1:len,], length=len, imputation = TRUE, inputed_timestep=47)
# write_csv(imputed_lockdown, "csvfiles/imputed_lockdown.csv")
imputed_vaccine <- get_posts_history(vaccine[1:len,], length=len, imputation = TRUE, inputed_timestep=47)
# write_csv(imputed_vaccine, "csvfiles/imputed_vaccine.csv")

imputed_trump <- get_posts_history(trump[1:len,], length=len, imputation = TRUE, inputed_timestep=47)
# write_csv(imputed_trump, "csvfiles/imputed_trump.csv")
imputed_biden <- get_posts_history(biden[1:len,], length=len, imputation = TRUE, inputed_timestep=47)
# write_csv(imputed_biden, "csvfiles/imputed_biden.csv")
imputed_jesus <- get_posts_history(jesus[1:len,], length=len, imputation = TRUE, inputed_timestep=47)
# write_csv(imputed_jesus, "csvfiles/imputed_jesus.csv")

####################################################
# create topic indicators
####################################################
imputed_mask = imputed_mask %>% mutate(mask=1, lockdown=0, vaccine=0, trump =0,  biden=0, jesus=0)
imputed_lockdown = imputed_lockdown %>% mutate(mask=0, lockdown=1, vaccine=0, trump =0,  biden=0, jesus=0)
imputed_vaccine = imputed_vaccine %>% mutate(mask=0, lockdown=0, vaccine=1, trump =0,  biden=0, jesus=0)

imputed_trump = imputed_trump %>% mutate(mask=0, lockdown=0, vaccine=0, trump =1,  biden=0, jesus=0)
imputed_biden = imputed_biden %>% mutate(mask=0, lockdown=0, vaccine=0, trump =0,  biden=1, jesus=0)
imputed_jesus = imputed_jesus %>% mutate(mask=0, lockdown=0, vaccine=0, trump =0,  biden=0, jesus=1)

####################################################
# Drop NA values
####################################################
imputed_data <-rbind(imputed_mask,imputed_lockdown,imputed_vaccine,
                     imputed_trump, imputed_biden, imputed_jesus
                     ) %>% drop_na()

####################################################
# Make account type indicators: facebook page/group
####################################################
imputed_data = imputed_data %>% 
  mutate(page = ifelse(accountType == "facebook_page",1,0)) %>% 
  mutate(group = ifelse(accountType == "facebook_group",1,0))

imputed_data_pid_message<- imputed_data %>%select(pid,message) %>% distinct()
# write_csv(imputed_data_pid_message, "csvfiles/imputed_data_pid_message.csv")



####################################################
# Seperate data with all features & data with only constant features
####################################################
imputed_data

allsteps_data <- imputed_data %>% 
  select(pid, score, starts_with("actual")) %>%
  group_by(pid) %>%
  group_map(~ flatten(.x))

constant_data <- imputed_data  %>%
  group_by(pid) %>%
  group_map(~ head(.x, 1L))


####################################################
# Data process to
# make post embeddings to variables
# slice time-series by sliding window
####################################################
post_emb <- read_csv("csvfiles/pid_embeddings_pca100.csv")[,-1]

records = vector()
vector_ts_all = vector()
for (i in 1:length(constant_data)) {
# for (i in 1:10) {
  print(i)
  # train_time=5
  vector_constant = constant_data[[i]] %>% 
    select(mask, lockdown, vaccine, trump, biden, jesus, page,group, verified, subscriberCount) %>%
    as.matrix() %>% 
    as.vector()
  vector_ts_all = allsteps_data[[i]]  %>% 
    select(score, starts_with("actual"))
  emb = post_emb[i,]%>%
    as.matrix() %>% 
    as.vector()
  for (train_time in 6:17) {
    vector_ts = vector_ts_all[(train_time-5):train_time,] %>% as.matrix() %>% as.vector()
    target = allsteps_data[[i]]$actual.shareCount[(train_time+1):(train_time+30)]%>% as.vector()
    one_record = c(emb, vector_constant, vector_ts, target)
    records = rbind(one_record,records)
  }
  # append(vector_constant, vector_ts, target) %>% as_tibble() %>% t()
}
records

recorddf <- as.data.frame(records)


####################################################
# Give column names
####################################################
colname_vector = c("mask", "lockdown", "vaccine", "trump", "biden", "jesus", "page","group", "verified", "subscriberCount")

for (i in 1:dim(vector_ts_all)[2] ) {
  colname_vector = c(colname_vector, paste(colnames(vector_ts_all)[i], 1:6, sep = ""))
}

colname_vector = c(paste("emb", 1:100, sep = ""), colname_vector, paste("Y", 6:35, sep = ""))
colnames(recorddf) = colname_vector
recorddf = recorddf %>% dplyr::select(-starts_with("actual.thankfulCount")) 
glimpse(recorddf)


####################################################
# Save the final data
####################################################
write_csv(recorddf, "csvfiles/share_pred_window.csv")