#Richard Shanahan  
#https://github.com/rjshanahan  
#rjshanahan@gmail.com
#5 Dec 2015

## load packages

library(shiny)
library(dplyr)
library(ggplot2)
library(devtools)


############################################################
## build data
############################################################


# IMPORT from server
growyourown <- read.csv('growyourown_recode_sentiment.csv',
                         header=T,
                         sep=",",
                         quote='"',
                         colClasses=c(                                      
                            'character',                             #"blog_text",             
                            'character',                             #"header",             
                            'character',                             #"url",                
                            'character',                             #"user",                   
                            'character',                             #"date",
                            'character',                             #"popularity",     
                            'numeric',                               #"like_fave",                      
                            'numeric',                               #"share_rtwt",                      
                            'character',                             #"id",  
                            'character',                             #"like_fav_group",  
                            'character',                             #"shr_rtwt_group",  
                            'character',                             #"source",                        
                            'character',                             #"hashtag",           
                            'character',                             #"polarity",
                            'numeric',                               #"polarity_confidence",
                            'character',                             #"subjectivity",
                            'numeric'                                #"subjectivity_confidence",
                   ),
                         strip.white=T,
                         stringsAsFactors=F,
                         fill=T)


#set theme for 'minimal' appearance in plots
theme = theme_set(theme_minimal())
theme = theme_update(legend.position="top")


#################################################################
## shiny server function
#################################################################

server <- function(input, output) {
  
  dataGraphic1 <- reactive({

    growyourown %>%
      mutate(paste0(input$myX," = substr(",input$myX,", 0, 30)")) %>%      
      group_by_(input$myX, quote(source), quote(polarity), quote(subjectivity)) %>%
      mutate(posts = n()) %>%
      select_(input$myX, quote(source), input$myY, quote(polarity), quote(subjectivity)) %>%
      filter(!is.na(input$myY) & !is.na(polarity) & source == input$mySource) %>%
      group_by_(input$myX, quote(source), quote(polarity), quote(subjectivity), input$myY) %>%
      summarise_(paste0("sum(",input$myY,")")) %>%
      ungroup() %>%
      arrange_(paste0("desc(",input$myY,")"))
    
  })
  
  
  dataGraphic2 <- reactive({
    
    growyourown %>%
      mutate(paste0(input$myX," = substr(",input$myX,", 0, 30)")) %>%      
      group_by_(input$myX, quote(source), quote(polarity), quote(subjectivity)) %>%
      mutate(posts = n()) %>%
      select_(input$myX, quote(source), input$myY, quote(polarity), quote(subjectivity)) %>%
      filter(!is.na(input$myY) & !is.na(polarity) & source == input$mySource) %>%
      group_by_(input$myX, quote(source), quote(polarity), quote(subjectivity), input$myY) %>%
      summarise_(paste0("sum(",input$myY,")")) %>%
      ungroup() %>%
      arrange_(paste0("desc(",input$myY,")"))
    
  })
  
  
  output$sentiment_plot <- renderPlot({
    
    myDF <- dataGraphic1()
    headmyDF <- arrange(head(myDF, n=input$topN))
    
    p <- ggplot(data = arrange(headmyDF, desc(polarity)), 
                #ordered x axis by popularity count.
                aes_string(x=paste0("factor(", input$myX, ", levels=unique(", headmyDF,"))"),
                           y=input$myY,
                           fill=quote('polarity'))) + 
      geom_bar(stat='identity') +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            title = element_text(size = 15, colour = "black"),
            axis.title = element_text(size = 15, colour = "black")) +
      ggtitle(paste("Sentiment by", input$myX,  "- showing the top", input$topN, "records")) +
      xlab(paste(input$myX)) +
      ylab(paste("Measure:", input$myY))
    
    print(p)
    
  })
  
  
  
  output$subjectivity_plot <- renderPlot({
    
    myDF <- dataGraphic2()
    headmyDF <- arrange(head(myDF, n=input$topN))
    
    p <- ggplot(data = arrange(headmyDF, desc(subjectivity)), 
                #ordered x axis by popularity count
                aes_string(x=paste0("factor(", input$myX, ", levels=unique(", headmyDF,"))"),
                           y=input$myY,
                    fill=quote('subjectivity'))) + 
      geom_bar(stat='identity') +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            title = element_text(size = 15, colour = "black"),
            axis.title = element_text(size = 15, colour = "black")) +
      ggtitle(paste("Subjectivity by", input$myX,  "- showing the top", input$topN, "records")) +
      xlab(paste(input$myX)) +
      ylab(paste("Measure:", input$myY))
    
    print(p)
    
  })
  
}
