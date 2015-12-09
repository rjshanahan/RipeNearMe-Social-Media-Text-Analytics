#Richard Shanahan  
#https://github.com/rjshanahan  
#rjshanahan@gmail.com
#5 December 2015

## load packages
library(shiny)
library(dplyr)
library(ggplot2)
library(devtools)


#GitHub URL
rjs <- as.character(tags$html(
  tags$body(
    a("my GitHub repository", href="https://github.com/rjshanahan/RipeNearMe-Social-Media-Text-Analytics", target="_blank"))))

selections_fill <- c('polarity',             
                'subjectivity')

selections_x <- c('user', 
                  'hashtag')

selections_y <- c('like_fave',
                  'share_rtwt',
                  'posts')

selections_source <- c('twitter',
                  'facebook',
                  'twitter_ripenearme')

selections_source_hash <- c('twitter',
                       'twitter_ripenearme')

############################################################
## shiny user interface function
############################################################

ui <- fluidPage(
  titlePanel('RipeNearMe Social Media Data Interactive Visualisations'),
  mainPanel(img(src="RNMlogo.png", height = 77, width = 300)),
  sidebarPanel(
    sliderInput(inputId="topN","How many users or hashtags do you wish to view?",value=30,min=10,max=50,step=1),
    radioButtons(inputId="myX", "Select your x-axis", selections_x, selected = selections_x[1], inline = T),
#     conditionalPanel(
#       condition = "input.mySource == 'facebook'",
#       radioButtons(inputId="myX", "Select your source", selections_x[1], selected = selections_x[1], inline = T)),
#     conditionalPanel(
#       condition = "input.mySource != 'facebook'",
#       radioButtons(inputId="myX", "Select your source", selections_x, selected = selections_x[1], inline = T)),
    radioButtons(inputId="myY", "Select your y-axis", selections_y, selected = selections_y[1], inline = T),
    conditionalPanel(
      condition = "input.myX == 'user'",
      radioButtons(inputId="mySource", "Select your source", selections_source, selected = selections_source[1], inline = T)),
    conditionalPanel(
      condition = "input.myX == 'hashtag'",
      radioButtons(inputId="mySource", "Select your source", selections_source_hash, selected = selections_source_hash[1], inline = T)),
    #radioButtons(inputId="mySource", "Select your source", selections_source, selected = selections_source[1], inline = T),
    helpText("For definitions and background information on this dataset and related code please refer to ",rjs),
    width=12),
  fluidRow(
    column(width=6, plotOutput("sentiment_plot")),
    column(width=6, plotOutput("subjectivity_plot")))
)



