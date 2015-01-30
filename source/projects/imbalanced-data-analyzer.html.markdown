---
title: Imbalanced Data Analyzer
date: 2014-12-27 22:20 UTC
tags:
cover_photo: ImbalancedPicture.jpg
description: Automated analyses of large sets of imbalanced data.
image_list:
  - imbalanceddata/ImbalancedPicture.jpg
stack:
  - Django
  - EmberJS
  - Scikit Learn
---

##### Tech Stack
Django, EmberJS, Scikit Learn, Celery, Redis, Pandas


##### Description
During my final semester of college, I took a course in Data Mining. The professor, [Nitesh Chawla](http://nd.edu/~chawla) is also my Research Advisor and Director at [iCeNSA](http://icensa.com/). For the class, he stated that my group and I could continue my research project, where Professor Chawla wanted a prototype for a *one-stop shop* web framework for automated classification of large sets of imbalanced data.

Since I was the only member of our team familiar with web development and also the research, I did a fair amount of the programming for this project. Thinking from a framework perspective, it made the most sense to use Django as our framework so we could utilize the various scientific and mathematical libraries that Python provides, more specifically [Pandas](http://pandas.pydata.org/) and [Scikit-Learn](http://scikit-learn.org/stable/). For building the API, we also decided to use [Django Rest Framework](http://www.django-rest-framework.org/). From Django's built-in admin panel, we could handle the upload and storage of dataset files to test our application on.

Whenever a user creates an analysis from the front-end application, the analysis is stored in the back-end and then processed in a background [Celery](http://celery.readthedocs.org) task, executing the selected classifier. After the Celery task is finished processing, the accuracy, precision, and f1 score, in addition to the support are saved into the database. Additionally, PNGs are created of the precision graphs and ROC curves and also saved, sending these back to the front-end. In the end, the project served as a successful proof-of-concept and starting point for the one-stop shop.