---
title: Notre Dame Class Search
date: 2014-12-27 22:09 UTC
slug: 'notre-dame-class-search'
tags:
description: Rails and EmberJS application for finding/scheduling classes at Notre Dame!
project_url: http://ndsearch.co
source_url: https://github.com/iheanyi/ClassSearch
cover_photo: NDSearchFull.png
image_list:
  - ndsearch/NDSearchFull.png
  - ndsearch/WorkingAgenda.png
skills:
  - Ruby on Rails
  - EmberJS
  - PostgreSQL

---


##### Technologies Used
EmberJS, Ruby on Rails, PostgreSQL


##### Description

During my final semester at the University of Notre Dame, I took a class called Interaction Design, where we were focusing on learning about User Experience and Human Computer Interaction. One of our two assignments was to choose an existing interface and improve upon it. For my interface of choice, I chose [Notre Dame's Class Search website](http://class-search.nd.edu), an interface which had frustrated me for the last 4.5 years.

While this project was my first project using [EmberJS](http://emberjs.com), it was also my first project to *completion* using Ruby on Rails. In order to grab all the courses from the Class Search database, I wrote a web scraper using [Nokogiri](http://nokogiri.org) and [HTTParty](https://github.com/jnunemaker/httparty) to scrape the Class Search website and save all of the relevant course information to my database. On Heroku, I had this scraper running every thirty minutes to have a relatively accurate number of the current seats in each course. Using this data, I was able to build an API using Ruby on Rails, which would later be consumed by my EmberJS application.

Rather than giving each section of the application (Departments/Professors/Attributes, Courses, and Course Detail), their own single page, I decided to contain the application to a three-column view for easier navigation around the application. Additionally, every section has its own search bar, allowing the user to search for specific items in the list at anytime rather than having to use the web browser's search function.

For handling the Agenda View, I modified the [FullCalendar](http://fullcalendar.io/) JQuery plugin to take in each specific course section as an event. In the back-end, rather than making more models to further complicate the view, I decided to quickly use the JSON column type recently added into Postgres. This allowed me to easily store each event's data and pass it back into the Agenda Component that I created in EmberJS.

Overall, my re-design of the Class Search interface was well-received by students of the University. At the time of writing, Class Search has 2,652 users, 3,592 sessions, and 4,230 pageviews. You can check out an article written by the Design apartment about my application [here](http://artdept.nd.edu/news-and-events/news/53707-iheanyi-ekechukwu-creates-nd-class-search/).