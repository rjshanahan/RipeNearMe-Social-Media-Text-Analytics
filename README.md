## RipeNearMe Social Media Text Analytics
![RipeNear.Me](http://www.ripenear.me/sites/all/themes/ripenearme/logo.png)
  
The repository includes code used to extract, process, integrate, model and visualise social media data related to the produce sharing site *<a href="http://www.ripenear.me/" target="_blank">Ripe Near Me</a>*  

####*<a href="https://rjshanahan.shinyapps.io/shiny_ripenearme01" target="_blank">Interactively explore RipeNearMe Social Media Text Analytics</a>* 

Code included in this repository:
- final dataset
- web scrapers for Facebook, Twitter and RipeNearMe blog entries (written in Python)
  - Facebook page and group *<a href="https://github.com/rjshanahan/facebook_m_scraper" target="_blank">webscraper</a>* 
  - Twitter *<a href="https://github.com/rjshanahan/twitter_scraper" target="_blank">webscraper</a>* 
- pre-processing, integration and feature selection code (written in R)
- sentiment analysis code using the Aylien API (written in Python)
- interactive visualisation code (written in R using the Shiny package)
- note: predictive modelling was undertaken in SAS Enterprise Miner

####Definitions for  <a href="https://rjshanahan.shinyapps.io/shiny_ripenearme01" target="_blank">interactive social media text analytics visualisation</a>
|Attribute										| Description                  | Visualisation Use  |
|:---------------------------------------------------|:-------|:---------------------|
|sentiment   							| Natural language processing was used to determine the overall *sentiment* of the post - was it **positive, negative or neutral**	| ```colouring```	  |
|subjetivity   							| Natural language processing was used to determine the overall *subjectivity* of the post - was it **subjective or objective**	| ```colouring```	  |
|user   							| the *user* name used to create the post	| ```x-axis```	  |
|hashtag 							| the *hashtag* used in the posts where applicable	| ```x-axis```	  |
|like_fave					| the total 'likes' or 'favorites' given to the post	| ```y-axis```	  |
|share_rtwt					| the total 'shares' or 'retweets' given to the post	| ```y-axis```	  |
|posts					| the total number of *posts* by user or hashtag	| ```y-axis```	  |
|twitter					| the post source	| ```filter```	  |
|facebook					| the post source	| ```filter```	  |
|twitter_ripenearme				| the post source - specifically when retrieved from the @RipeNearMe Twitter account	| ```filter```	  |
Note: sentiment and subjectivity analysis was undertaken using the <a href="http://aylien.com/" target="_blank">Python API from Aylien </a>

![Aylien](http://aylien.com/images/graph.png)


####Datasources - 2015 data
|URL										| Site                  |
|:---------------------------------------------------|:-------|
|https://twitter.com/hashtag/growyourown				| Twitter	|
|https://twitter.com/ripenearme			| Twitter	|
|http://www.ripenear.me/blog				| RipeNearMe	|
|https://m.facebook.com/groups/JETTOSPATCH/   							| Facebook	|
|https://m.facebook.com/groups/335757083118409/							| Facebook	|
|https://m.facebook.com/groups/447193975415704/						| Facebook	|
|https://m.facebook.com/Bitsouttheback/					| Facebook	|
|https://m.facebook.com/groups/QC.EdibleLandscape/				| Facebook	|
|https://m.facebook.com/groups/dig.your.way.to.a.better.world/				| Facebook	|




