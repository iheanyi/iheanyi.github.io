---
title: User Registration/Authentication with Django, Django Rest Framework, React, and Redux
date: 2015-12-28 17:26 UTC
tags: django, react, redux, user authentication, django rest framework, drf
published: false
---

In this tutorial I will show how to build a simple user registration and login
form using Django, Django Rest Framework, React, and Redux. For the purpose of
this tutorial, I won't include the tests in the blog post, but you can find the
tests in the [GitHub repo]().

## Django Project Setup

First, install Django and Django Rest Framework[^1].  

```shell
pip install django djangorestframework
```

Then, create a new Django project. 

```
django-admin startproject django_react_users_tutorial
```

Now we have to add DRF[^2] to the list of installed apps for our new project. `cd` into the newly created Django project and open up the `settings.py` and add `rest_framework` to the `INSTALLED_APPS` setting.

```python
# django_react_users_tutorial/settings.py

INSTALLED_APPS = (
    ...
    'rest_framework',
)
```

Let's go ahead and sync our database.

```
python manage.py syncdb
```

Now we're ready to start coding up the actual API logic. Let's start with user registration.

## User Registration - Serializers

Let's create a new Django application for handling user accounts.

```shell
python manage.py startapp accounts
```
The app has the name `accounts` since we are creating accounts but also may want
to have other functionality such as editing or deleting. In the newly created
`accounts` folder, create a `serializers.py` file. For this tutorial, we're
going to use Django's built-in user model. At the bare minimum, we want
our registered users to have a `username`, `email`, and `password`. Let's
define a `UserSerializer` for DRF, which is merely an API representation of our
model.

```python
from rest_framework import serializers
from rest_framework.validators import UniqueValidator
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(
            required=True,
            validators=[UniqueValidator(queryset=User.objects.all())]
            )
    username = serializers.CharField(
            validators=[UniqueValidator(queryset=User.objects.all())]
            )
    password = serializers.CharField(min_length=6, max_length=100)

    def create(self, validated_data):
        user = User.objects.create_user(validated_data['username'], validated_data['email'],
             validated_data['password'])
        return user

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')
```

Let's dissect this code further, shall we? 

```python
class UserSerializer(serializers.ModelSerializer):
```

Here we are inheriting from a ModelSerializer, which automatically generates
validators for the serializer based on the model.

```python
email = serializers.EmailField(
            required=True,
            validators=[UniqueValidator(queryset=User.objects.all())]
            )
```

Here we are stating that the type of this attribute is an `EmailField` and that
it is required and should be unique amongst all `User` objects in our database.

```python
username = serializers.CharField(
            validators=[UniqueValidator(queryset=User.objects.all())]
            )
```

Similar to `email`, we want to make sure all usernames in the database are
unique as well.

```python
def create(self, validated_data):
    user = User.objects.create_user(validated_data['username'], validated_data['email'],
             validated_data['password'])
    return user
```

When creating a new `User` using Django's built-in authentication system, the
regular `create` method won't work, so we have to use the `create_user` method
from the `User` class.

```python
class Meta:
    model = User
    fields = ('id', 'username', 'email', 'password')
```

This is stating that for our `UserSerializer`, the corresponding model is `User`
and these are the fields that it contains. Now that we have our serializer,
we're ready to create the view!

## User Registration - Views

Let's start by opening `accounts/tests.py` and adding in a simple test for
creating a new user.

```python
from django.core.urlresolvers import reverse
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from rest_framework import status

class AccountsTest(APITestCase):
    def setUp(self):
        # We want to go ahead and originally create a user. 
        self.test_user = User.objects.create_user('testuser', 'test@example.com', 'testpassword')
        
        # URL for creating an account.
        self.create_url = reverse('account-create')

    def test_create_user(self):
        """
        Ensure we can create a new user and a valid token is created with it.
        """
        data = {
            'username': 'foobar',
            'email': 'foobar@example.com',
            'password': 'somepassword'
        }

        response = self.client.post(self.create_url , data, format='json')
      
        # We want to make sure we have two users in the database..
        self.assertEqual(User.objects.count(), 2)
        # And that we're returning a 201 created code.
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        # Additionally, we want to return the username and email upon successful creation.
        self.assertEqual(response.data['username'], data['username'])
        self.assertEqual(response.data['email'], data['email'])
        self.assertFalse('password' in response.data)
```

In the above snippet of code, there is one key detail to notice here.
```python
from rest_framework.test import APITestCase

class AccountsTest(APITestCase):
```

Rather than using the `TestCase` class from Django, we're using `APITestCase`
from DRF instead. If you run `python manage.py test`, you should see the
following error.

```
NoReverseMatch: Reverse for 'account-create' with arguments '()' and keyword arguments '{}' not found. 0 pattern(s) tried: []
```

This is because we haven't even created a URL with that name yet! So let's go
ahead and create a basic view and URL. Open up `accounts/views.py` and add the
following code.

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from accounts.serializers import UserSerializer
from django.contrib.auth.models import User

class UserCreate(APIView):
    """ 
    Creates the user. 
    """

    def post(self, request, format='json'):
        return Response('hello')
```

What we're doing here is defining an APIView for creating our user. Don't worry,
we'll add the creation logic soon enough.

Next, create a `urls.py` folder in `accounts` (accounts/urls.py`) and add the following code.

```python
from django.conf.urls import url
from . import views

urlpatterns = [
    url(r'api/users^$', views.UserCreate.as_view(), name='account-create'),
]
```
And we have to make sure we're referencing these URLs in our sites main URLs
file, so modify `react_django_users_tutorial/urls.py` to be like the following:

```python
from django.conf.urls import include, url
from django.contrib import admin

urlpatterns = [
    url(r'^users/', include('accounts.urls')),
]
```

Now, let's run `python manage.py test` again and see the output.

```
AssertionError: 1 != 2
```

At our endpoint, we're not creating the User object, so let's change that up.
Tweak `accounts/views.py` and change up `UserCreate` to the following.

```python
...

class UserCreate(APIView):
    """ 
    Creates the user. 
    """

    def post(self, request, format='json'):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            if user:
                return Response(serializer.data, status=status.HTTP_201_CREATED)
```

Let's run our tests again and see what it outputs now.

```
# python manage.py test
    self.assertFalse('password' in response.data)
AssertionError: True is not false
```

Uh-oh, we're returning a password in the payload returned upon succcessful
authentication. Let's re-open `accounts/serializers.py` and tweak the `password`
field to be `write_only`.

```python
...
password = serializers.CharField(min_length=6, max_length=100, write_only=True)
...
```

Now run the tests one more time using `python manage.py test` and let's see what
it outputs.

```
.
----------------------------------------------------------------------
Ran 1 test in 0.053s

OK
```

Awesome, we got a basic version of registration working now!





[^1]: The latest version of Django is 1.9 at the time of this tutorial. Also, make sure you are using [virtualenv]() for this project.
[^2]: Django Rest Framework.
