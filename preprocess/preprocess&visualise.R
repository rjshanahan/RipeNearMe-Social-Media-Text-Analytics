#Richard Shanahan  
#https://github.com/rjshanahan  
#17 August 2015

###### Ripe Near Me Social Media Data Analytics

# load required packages
library(Hmisc)
library(psych)
require(devtools)
library(ggplot2)
library(dplyr)
library(reshape2)


# source custom code for plots from GitHub Gist: https://gist.github.com/rjshanahan
source_gist("e47c35277a36dca7189a")       #boxplot
source_gist("7eed7f043c987f884748")       #facet wrap boxplot
source_gist("40f46687d48030d40704")       #cluster plot


############## 0 READ IN FINAL DATA FROM GITHUB ##############

library(devtools)
source_gist("4a06c7de50f5b6033678")

source_csv_file_url <- 'https://raw.githubusercontent.com/rjshanahan/RipeNearMe-Web-Scraper/master/dataset/growyourown_recode_sentiment.csv'
missing_types <- c("NA", "")

growyourown <- source_GitHubData_vaccination(source_csv_file_url, ",", header=T)

str(growyourown)


###### 1. read in file pre-sentiment analysis and inspect data ###### 

growyourown <- read.csv('growyourown_consolidated.csv',
                        header=T,
                        sep=",",
                        quote='"',
                        colClasses=c(
                          'character',   # header
                          'character',   # url
                          'character',   # user
                          'character',   # date
                          'character',   # popularity
                          'character',   # blog_text
                          'numeric',     # like_fave
                          'numeric'      # share_rtwt
                        ),
                        strip.white=T,
                        stringsAsFactors=F,
                        fill=T)


#inspect
str(growyourown)
describe(growyourown)

#check for duplicate records based
nrow(unique(growyourown))
nrow(growyourown)

#check if there are any missing values
colSums(is.na(growyourown)) 

#add id variable
growyourown$id <- 1:nrow(growyourown)


###### 2. recode and feature selection ###### 
# recode Likes and Favorites
growyourown$like_fav_group <- ifelse(growyourown$like_fave >= 9,
                                     "High",
                                     ifelse(growyourown$like_fave > 2.96 & growyourown$like_fave < 9,
                                            "Medium",
                                            ifelse(growyourown$like_fave >= 1 & growyourown$like_fave <= 2.96,
                                                   "Low",
                                                   "None")))

growyourown$like_fav_group[is.na(growyourown$like_fav_group)] <- "None"

# recode Shares and Retweets
growyourown$shr_rtwt_group <- ifelse(growyourown$share_rtwt >= 9,
                                     "High",
                                     ifelse(growyourown$share_rtwt > 2.96  & growyourown$share_rtwt < 9,
                                            "Medium",
                                            ifelse(growyourown$share_rtwt >= 1 & growyourown$share_rtwt <= 2.96,
                                                   "Low",
                                                   "None")))

growyourown$shr_rtwt_group[is.na(growyourown$shr_rtwt_group)] <- "None"

#like_fave ranges
mR <- median(growyourown$like_fave, na.rm = T)
madR <- mad(growyourown$like_fave, na.rm = T)
iqrR <- IQR(growyourown$like_fave, na.rm = T)


#share_retweet ranges
mR <- median(growyourown$share_rtwt, na.rm = T)
madR <- mad(growyourown$share_rtwt, na.rm = T)
iqrR <- IQR(growyourown$share_rtwt, na.rm = T)




######additional variable for SOURCE
fb = 'facebook'
tw = 'twitter'
tw_ripe = 'twitter_hashtag_ripenearme'

#additional recode - add SOURCE
#growyourown$source <- ifelse(grepl(fb, growyourown$header) == T,
#                             "facebook",
#                             ifelse(grepl(tw, growyourown$header) == T,
#                                    "twitter",
#                                    "other"))

growyourown$source <- ifelse(grepl(fb, growyourown$header) == T,
                             "facebook",
                             ifelse(grepl(tw_ripe, growyourown$header) == T,
                                    "twitter_ripenearme",
                                    ifelse(grepl(tw, growyourown$header) == T,
                                           "twitter",
                                           "other")))

table(growyourown$source)


#####additional variable for Hashtag
growyourown$hashtag <- ifelse(sub("^([A-Z]+)[0-9]+", "\\1",
                          sapply(growyourown$blog_text, 
                                 function(x) regmatches(x, regexpr("(#)\\w+", x)))) == 'character(0)',
                      "",
                      sub("^([A-Z]+)[0-9]+", "\\1",
                          sapply(growyourown$blog_text, 
                                 function(x) regmatches(x, regexpr("(#)\\w+", x)))))


#write output file
write.csv(growyourown, file = "growyourown_recode.csv", row.names = FALSE)

###### 3. visualisations ###### 


#inspect popularity metrics - LOG TRANSFORMED
ggplot(data = growyourown, 
       aes(x=log(like_fave),
           fill=like_fav_group)) + 
  #fill=ring_group)) + 
  geom_histogram(binwidth=0.1) +
  ggtitle("growyourown: Histogram of 'Likes' + 'Favorites' (log) and Favorites")

ggplot(data = growyourown, 
       aes(x=log(share_rtwt),
           fill=shr_rtwt_group)) + 
  #fill=ring_group)) + 
  geom_histogram(binwidth=0.1) +
  ggtitle("growyourown: Histogram of 'Shares' + 'Retweets' (log) and Favorites")


#inspect popularity metrics - GROUPING VARIABLE
ggplot(data = growyourown, 
       aes(x=like_fav_group,
           fill=like_fav_group)) + 
  #fill=ring_group)) + 
  geom_histogram(binwidth=5) +
  ggtitle("growyourown: Histogram of Likes and Favorites groups")

ggplot(data = growyourown, 
       aes(x=shr_rtwt_group,
           fill=shr_rtwt_group)) + 
  #fill=ring_group)) + 
  geom_histogram(binwidth=5) +
  ggtitle("growyourown: Histogram of Shares and Retweets")

#tabulate
table(growyourown$like_fav_group)
table(growyourown$shr_rtwt_group)






#user based visualisations

likefave_10 <-  growyourown %>%
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, posts) %>%
  filter(!is.na(like_fave)) %>%
  group_by(user, source, posts) %>%
  summarise(like_fave_sum = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave_sum)) 

head(likefave_10, 20)


shrtwt_10 <-  growyourown %>%
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, share_rtwt, posts) %>%
  filter(!is.na(share_rtwt)) %>%
  group_by(user, source, posts) %>%
  summarise(shr_rtwt_sum = sum(share_rtwt)) %>%
  ungroup() %>%
  arrange(desc(shr_rtwt_sum))

head(shrtwt_10, 20)

likefave_10_fb <-  growyourown %>%
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, posts) %>%
  filter(!is.na(like_fave) & source == 'facebook') %>%
  group_by(user, source, posts) %>%
  summarise(like_fave_sum = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave_sum))

head(likefave_10_fb, 20)


shrtwt_10_fb <-  growyourown %>%
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, share_rtwt, posts) %>%
  filter(!is.na(share_rtwt) & source == 'facebook') %>%
  group_by(user, source, posts) %>%
  summarise(shr_rtwt_sum = sum(share_rtwt)) %>%
  ungroup() %>%
  arrange(desc(shr_rtwt_sum))

head(shrtwt_10_fb, 20)


likefave_10_tw <-  growyourown %>%
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, posts) %>%
  filter(!is.na(like_fave) & source == 'twitter') %>%
  group_by(user, source, posts) %>%
  summarise(like_fave_sum = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave_sum))

head(likefave_10_tw, 20)


shrtwt_10_tw <-  growyourown %>%
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, share_rtwt, posts) %>%
  filter(!is.na(share_rtwt) & source == 'twitter') %>%
  group_by(user, source, posts) %>%
  summarise(shr_rtwt_sum = sum(share_rtwt)) %>%
  ungroup() %>%
  arrange(desc(shr_rtwt_sum))

head(shrtwt_10_tw, 20)



#visualise posts by users
ggplot(data = arrange(head(likefave_10, 10)), 
       aes(x=substr(user, 0, 30),
           y=like_fave_sum,
           fill=sentiment,
           alpha=posts)) + 
  geom_bar(stat='identity') +
  #facet_grid(~ source) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Top 10 Most Popular Users by Likes & Favorites") +
  xlab("User Name") +
  ylab("Popularity count")


ggplot(data = arrange(head(likefave_10, 10)), 
       aes(x=substr(user, 0, 30),
           y=like_fave_sum,
           fill=source)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Top 10 Most Popular Users by Likes & Favorites") +
  xlab("User Name") +
  ylab("Popularity count")


ggplot(data = arrange(head(shrtwt_10, 10)), 
       aes(x=substr(user, 0, 30),
           y=shr_rtwt_sum,
           fill=source)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Top 10 Most Popular Users by Shares & Retweets") +
  xlab("User Name") +
  ylab("Popularity count")


ggplot(data = arrange(head(likefave_10, 10)), 
       aes(x=substr(user, 0, 30),
           y=like_fave_sum,
           fill=posts)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Top 10 Most Popular Users by Likes & Favorites - weighted by Posts") +
  xlab("User Name") +
  ylab("Popularity count")


ggplot(data = arrange(head(shrtwt_10, 10)), 
       aes(x=substr(user, 0, 30),
           y=shr_rtwt_sum,
           fill=posts)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Top 10 Most Popular Users by Shares & Retweets - weighted by Posts") +
  xlab("User Name") +
  ylab("Popularity count")


#visualise posts by users + source
ggplot(data = arrange(head(likefave_10_fb, 10)), 
       aes(x=substr(user, 0, 30),
           y=like_fave_sum,
           fill=user)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position="none") +
  ggtitle("Top 10 Most Popular Facebook Users by Likes") +
  xlab("User Name") +
  ylab("Popularity count")


ggplot(data = arrange(head(shrtwt_10_fb, 10)), 
       aes(x=substr(user, 0, 30),
           y=shr_rtwt_sum,
           fill=user)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position="none") +
  ggtitle("Top 10 Most Popular Facebook Users by Shares") +
  xlab("User Name") +
  ylab("Popularity count")


ggplot(data = arrange(head(likefave_10_tw, 10)), 
       aes(x=substr(user, 0, 30),
           y=like_fave_sum,
           fill=user)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position="none") +
  ggtitle("Top 10 Most Popular Twitter Users by Favorites") +
  xlab("User Name") +
  ylab("Popularity count") 


shrtwt_10_tw <- shrtwt_10_tw[order(shrtwt_10_tw$user, shrtwt_10_tw$shr_rtwt_sum),]

ggplot(data=arrange(head(shrtwt_10_tw, 10)), 
       aes(x=substr(user, 0, 30),
           y=shr_rtwt_sum,
           fill=user)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position="none") +
  ggtitle("Top 10 Most Popular Twitter Users by Retweets") +
  xlab("User Name") +
  ylab("Popularity count")


##### 4. Sentiment #####

growyourown_sentiment <- read.csv('growyourown_sentiment.csv',
                        header=T,
                        sep=",",
                        quote='"',
                        colClasses=c(
                          'character',   # polarity
                          'numeric',     # polarity_confidence
                          'character',   # subjectivity
                          'numeric',     # subjectivity_confidence
                          'character'    # blog_text
                        ),
                        strip.white=T,
                        stringsAsFactors=F,
                        fill=T)

#inspect
str(growyourown_sentiment)

#drop extra NA variable
growyourown_sentiment <- select(growyourown_sentiment, 
                                polarity, polarity_confidence, subjectivity, subjectivity_confidence, blog_text)

#inspect
str(growyourown_sentiment)

#merge sentiment dataframe with original
growyourown <- merge(growyourown,
            growyourown_sentiment,
            by = 'blog_text',
            #all = T)
            all.x = T)

#remove duplicates
growyourown <- unique(growyourown)
str(growyourown)





############## 4.1 sentiment "facebook" visualisations ##############
sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity, like_fave) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity) %>%
  filter(!is.na(like_fave) & !is.na(polarity) & source == 'facebook') %>%
  group_by(user, source, polarity, subjectivity, like_fave) %>%
  #summarise(summariser = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Facebook Users by Likes and Sentiment") +
  xlab("User Name") +
  ylab("Popularity count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Facebook Users by Likes and Subjectivity") +
  xlab("User Name") +
  ylab("Popularity count") 


sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity, posts) %>%
  filter(!is.na(like_fave) & !is.na(polarity) & source == 'facebook') %>%
  group_by(user, source, polarity, subjectivity, posts) %>%
  summarise(summariser = sum(posts)) %>%
  ungroup() %>%
  arrange(desc(posts, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=posts,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Facebook Users by Posts and Sentiment") +
  xlab("User Name") +
  ylab("Posts count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=posts,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Facebook Users by Posts and Subjectivity") +
  xlab("User Name") +
  ylab("Posts count") 


############## 4.2 sentiment "twitter" visualisations ##############
sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity) %>%
  filter(!is.na(like_fave) & !is.na(polarity) & source == 'twitter') %>%
  group_by(user, source, polarity, subjectivity, like_fave) %>%
  summarise(summariser = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter Users by Likes and Sentiment") +
  xlab("User Name") +
  ylab("Popularity count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter Users by Likes and Subjectivity") +
  xlab("User Name") +
  ylab("Popularity count") 


sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity, posts) %>%
  filter(!is.na(like_fave) & !is.na(polarity) & source == 'twitter') %>%
  group_by(user, source, polarity, subjectivity, posts) %>%
  summarise(summariser = sum(posts)) %>%
  ungroup() %>%
  arrange(desc(posts, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=posts,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter Users by Posts and Sentiment") +
  xlab("User Name") +
  ylab("Posts count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=posts,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter Users by Posts and Subjectivity") +
  xlab("User Name") +
  ylab("Posts count") 



############## 4.3 sentiment "twitter_ripenearme" visualisations ##############
sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity) %>%
  filter(!is.na(like_fave) & !is.na(polarity) & source == 'twitter_ripenearme') %>%
  group_by(user, source, polarity, subjectivity, like_fave) %>%
  summarise(summariser = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter RipeNearMe Hashtag Users by Likes and Sentiment") +
  xlab("User Name") +
  ylab("Popularity count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter RipeNearMe Hashtag Users by Likes and Subjectivity") +
  xlab("User Name") +
  ylab("Popularity count") 


sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity, posts) %>%
  filter(!is.na(like_fave) & !is.na(polarity) & source == 'twitter_ripenearme') %>%
  group_by(user, source, polarity, subjectivity, posts) %>%
  summarise(summariser = sum(posts)) %>%
  ungroup() %>%
  arrange(desc(posts, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=posts,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter RipeNearMe Hashtag Users by Posts and Sentiment") +
  xlab("User Name") +
  ylab("Posts count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=posts,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Twitter RipeNearMe Hashtag Users by Posts and Subjectivity") +
  xlab("User Name") +
  ylab("Posts count") 


############## 4.4 sentiment "overall" visualisations ##############
sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity, posts) %>%
  filter(!is.na(like_fave) & !is.na(polarity)) %>%
  group_by(user, source, polarity, subjectivity, like_fave, posts) %>%
  summarise(summariser = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(summariser, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Users by Likes and Sentiment (all sites)") +
  xlab("User Name") +
  ylab("Popularity count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
          y=like_fave,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Users by Likes and Subjectivity (all sites)") +
  xlab("User Name") +
  ylab("Popularity count") 


sentiment_likefave_fb <-  growyourown %>%
  mutate(user = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(user, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(user, source, like_fave, polarity, subjectivity, posts) %>%
  filter(!is.na(like_fave) & !is.na(polarity)) %>%
  group_by(user, source, polarity, subjectivity, posts) %>%
  summarise(summariser = sum(posts)) %>%
  ungroup() %>%
  arrange(desc(posts, user))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
           y=posts,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Users by Posts and Sentiment (all sites)") +
  xlab("User Name") +
  ylab("Posts count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(user, levels=(unique(head(sentiment_likefave_fb, 50)$user))),     
           y=posts,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Users by Posts and Subjectivity (all sites)") +
  xlab("User Name") +
  ylab("Posts count") 


############## 4.5 sentiment "twitter" HASHTAG visualisations ##############
sentiment_likefave_fb <-  growyourown %>%
  mutate(hash = substr(hashtag, 0, 30)) %>%       #this creates shorter version of username
  group_by(hash, source, polarity, subjectivity, like_fave) %>%
  mutate(posts = n()) %>%
  select(hash, source, like_fave, polarity, subjectivity) %>%
  filter(hash != "" & !is.na(like_fave) & !is.na(polarity) & source == 'twitter') %>%
  group_by(hash, source, polarity, subjectivity, like_fave) %>%
  #summarise(summariser = sum(like_fave)) %>%
  ungroup() %>%
  arrange(desc(like_fave, hash))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(hash, levels=(unique(head(sentiment_likefave_fb, 50)$hash))),     
           y=like_fave,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Hashtags by Likes and Sentiment") +
  xlab("Hashtag") +
  ylab("Popularity count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(hash, levels=(unique(head(sentiment_likefave_fb, 50)$hash))),     
           y=like_fave,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Hashtags by Likes and Subjectivity") +
  xlab("Hashtag") +
  ylab("Popularity count") 




sentiment_likefave_fb <-  growyourown %>%
  mutate(hash = substr(user, 0, 30)) %>%       #this creates shorter version of username
  group_by(hash, source, polarity, subjectivity) %>%
  mutate(posts = n()) %>%
  select(hash, source, like_fave, polarity, subjectivity, posts) %>%
  filter(hash != "" & !is.na(like_fave) & !is.na(polarity)) %>%
  group_by(hash, source, polarity, subjectivity, posts) %>%
  summarise(summariser = sum(posts)) %>%
  ungroup() %>%
  arrange(desc(posts, hash))

head(sentiment_likefave_fb, 20)


ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(polarity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(hash, levels=(unique(head(sentiment_likefave_fb, 50)$hash))),     
           y=posts,
           fill=polarity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Hashtags by Posts and Sentiment (all sites)") +
  xlab("Hashtag") +
  ylab("Posts count") 

ggplot(data = arrange(head(sentiment_likefave_fb, 50), desc(subjectivity)), 
       #ordered x axis by popularity count. For alpha order just include 'user' instead
       aes(x=factor(hash, levels=(unique(head(sentiment_likefave_fb, 50)$hash))),     
           y=posts,
           fill=subjectivity)) + 
  geom_bar(stat='identity') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        title = element_text(size = 15, colour = "black"),
        axis.title = element_text(size = 15, colour = "black")) +
  ggtitle("Top 50 Most Popular Hashtags by Posts and Subjectivity (all sites)") +
  xlab("Hashtag") +
  ylab("Posts count") 


#write output file
write.csv(filter(growyourown, !is.na(polarity)), 
          file = "growyourown_recode_sentiment.csv", 
          #col.names = TRUE, 
          row.names = FALSE)
