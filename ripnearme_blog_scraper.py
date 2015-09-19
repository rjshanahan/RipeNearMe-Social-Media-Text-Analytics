#!/usr/bin/env python
# -*- coding: utf-8 -*-

from bs4 import BeautifulSoup
import urllib2
import requests
import codecs
import csv
import pprint as pp
import re


url_standard = 'http://www.ripenear.me/blog'    
url_next_page = '?page='


#web request function
def make_request_get(data):

    r = requests.get(data)

    return r.text


#function to build URL list for each blog entry nd page
def url_extract(url_standard):
    
    url_list = []    
    
    #initial blog page
    soup = BeautifulSoup(make_request_get(url_standard), "html.parser")
    
    for i in soup.find_all('span', {'class':'field-content'}):

        if i.a != None and i.a["href"].startswith('/blog'):
            url_list.append('http://www.ripenear.me' + i.a["href"])
        else:
            pass
  
    #subsequent blog pages
    n = 1
    
    while (len(make_request_get(url_standard+url_next_page+str(n))) > 30800) is True:     # 30800 is the length of non-existent blogpage
        soup = BeautifulSoup(make_request_get(url_standard+url_next_page+str(n)), "html.parser")
    
        for i in soup.find_all('span', {'class':'field-content'}):

            if i.a != None and i.a["href"].startswith('/blog'):
                url_list.append('http://www.ripenear.me' + i.a["href"])
            else:
                pass                       
            n += 1

    return blogxtract(url_list)



#build dictionary of desired values
def blogxtract(url_list):
        
    problemchars = re.compile(r'[\[=\+/&<>;:!\\|*^\'"\?%#$@)(_\,\.\t\r\n0-9-—\]]')
    prochar = '[(=\+\-\:/&<>;\'"\?%#$@\,\._)]'
    
    blog_list = []
    
    for u in url_list:

        soup = BeautifulSoup(make_request_get(u), "html.parser")

        for i in soup.find_all('div', {'class':"content"}):
    
            text_list = []
            text_list_final = []
        
            #define key:values for dictionary
            header = (i.find('h2').get_text().encode('ascii', 'ignore').strip().lower().translate(None, ''.join(prochar)) if i.find('h2') is not None else "")
            date = (i.p.span.contents[2].replace('on ','').encode('ascii', 'ignore').strip().lower().translate(None, ''.join(prochar)) if i.p.span is not None else "")
            user = (i.p.span.find('a').text.encode('ascii', 'ignore').strip().lower().translate(None, ''.join(prochar)) if i.p.span is not None else "")
    
            #if + loop for blog entries with different CSS values
            if len(i.find_all('span', {'style':'background-color:transparent; color:rgb(0, 0, 0); font-family:arial; font-size:15px'})) != 0:
                for j in i.find_all('span', {'style':'background-color:transparent; color:rgb(0, 0, 0); font-family:arial; font-size:15px'}):
                    text_list.append(j.get_text().lower().replace('\n',' ').replace("'", "").encode('ascii', 'ignore').strip())
            elif len(i.find_all('p')) != 0:
                for j in i.find_all('p'):
                    text_list.append(j.get_text().lower().replace('\n',' ').replace("'", "").encode('ascii', 'ignore').strip())
            else:
                pass
                   
                
            #replace bad characters in blog text
            for ch in prochar:
                for l in text_list:
                    if ch in l:
                        l = problemchars.sub(' ', l).strip()
                        text_list_final.append(l)
            
            #build dictionary
            blog_dict = {
            "header": (header if len(header) != 0 else u.split('blog/',1)[1].replace('-',' ').encode('ascii', 'ignore').strip().lower().translate(None, ''.join(prochar))),
            "user": (user if len(user) != 0 else (i.find('h5').text.encode('ascii', 'ignore').strip().lower().translate(None, ''.join(prochar)) if len(user) == 0 else "")),
            "date": (date if len(date) != 0 else (i.parent.find('abbr', {'class':None}).text.encode('ascii', 'ignore').strip().lower() if i.parent.find('abbr', {'class':None}) is not None else "")),
            "blog_text": ' '.join(text_list_final)
                }
        
            blog_list.append(blog_dict)
        
     
    #call csv writer function and output file
    writer_csv_3(blog_list)
    
    return pp.pprint(blog_list)



#function to write CSV
def writer_csv_3(blog_list):
    
    #file_out = "ripenearme{page}.csv".format(page = url.split('blog/',1)[1])
    file_out = "ripenearme_blogs.csv"
    
    with open(file_out, 'w') as csvfile:

        writer = csv.writer(csvfile, lineterminator='\n', delimiter=',', quotechar='"')
    
        for i in blog_list:
            newrow = i['header'], i['user'], i['date'], i['blog_text']
            writer.writerow(newrow)                     
    
    
#tip the domino    
url_extract(url_standard)

