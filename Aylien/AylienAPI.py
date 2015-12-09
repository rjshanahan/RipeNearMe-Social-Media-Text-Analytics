#AYLIEN Text Analysis API

import csv
from aylienapiclient import textapi

#rjshanahan
my_aylien = textapi.Client("your API KEY", "your API CODE")
        
growyourown_list = []
with open('TEXTFILE for ANALYSIS.csv', 'rb') as csvfile:
    growyourown = csv.DictReader(csvfile)
    for i in growyourown:
        growyourown_list.append(i)


text_only = []
for i in growyourown_list:
    text_only.append(i['blog_text'])
        
        
growyourown_sentiment = [] 
for i in text_only:
    growyourown_sentiment.append(my_aylien.Sentiment(i))
    
    
#function to write CSV file
def writer_csv(output_list):
    
    file_out = "auu_sentiment.csv"

    with open(file_out, 'w') as csvfile:
        col_labels = ['polarity', 'polarity_confidence', 'subjectivity', 'subjectivity_confidence', 'blog_text']
        
        writer = csv.writer(csvfile, lineterminator='\n', delimiter=',', quotechar='"')
        newrow = col_labels
        writer.writerow(newrow)
        
        for i in output_list:
            
            newrow = i['polarity'], i['polarity_confidence'], i['subjectivity'], i['subjectivity_confidence'], i['text']
            writer.writerow(newrow)   
            

writer_csv(growyourown_sentiment)

