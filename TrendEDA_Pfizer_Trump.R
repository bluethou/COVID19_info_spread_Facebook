library(httr)
library(tidyverse)
library(lubridate)
library(jsonlite)
site_url = "https://api.crowdtangle.com/links"
auth_key = "I2RzFgrfvPFWruFXRDrswizIDz2raQZtZP9yCmVt"
list_id = 1472769
searchTerm = "COVID-19"
sortBy = "subscriber_count"
count = 1000

# This is a function to track posts sharing a specific URL
get_link <- function(startDate = "2020-11-05", 
                     link="https://www.pfizer.com/news/press-release/press-release-detail/pfizer-and-biontech-announce-vaccine-candidate-against"){
  query_str = paste(site_url, "?token=", auth_key, "&link=",link, "&startDate=",startDate,"&count=", count, "&sortBy=",sortBy,sep = "")
  resp = GET(query_str,add_headers("Authorization"=auth_key))
  resp.str = as.character(resp)
  d= fromJSON(resp.str)
  d$result$posts
}

# posts that share Pfizer's vaccine news
posts = get_link() 

# posts that share  Trumps' argument:
# posts = get_link("https://www.facebook.com/DonaldTrump/posts/10165703998545725", startDate="2020-10-27")

posts %>% glimpse()
posts$veri = posts$account$verified
posts$date = posts$date %>% lubridate::as_datetime()  %>% round_date("hour")
posts$veri %>% table()

### Plot sharing patterns by verification
trend <- posts %>% filter(veri==FALSE)%>% group_by(date) %>% summarise(count=n())
trend2 <- posts %>% filter(veri==TRUE)%>% group_by(date) %>% summarise(count=n())

plot(trend, col='red', cex= 0.9, xlab("Date"), ylab("posts count"), title("News spread"))
points(trend2, col='blue', cex= 0.9)
legend("topright",
       c("not_verified","verified"),
       fill=c("red","blue")
)

