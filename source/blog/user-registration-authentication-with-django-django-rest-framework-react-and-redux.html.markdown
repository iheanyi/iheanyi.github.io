---
title: User Registration/Authentication with Django, Django Rest Framework, React, and Redux
date: 2015-12-28 17:26 UTC
tags: django, react, redux, user authentication, django rest framework, drf
published: false
---

In this tutorial I will show how to build a simple user registration and login
form using Django, Django Rest Framework, React, and Redux. For the purpose of
this tutorial, I won't include the tests in the blog post, but you can find the
tests in the [GitHub repo](https://github.com/iheanyi/django-react-redux-users-tutorial).

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

Let's go ahead and migrate our database so everything is initially created.

```
python manage.py migrate
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
    password = serializers.CharField(min_length=8)

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
creating a new user called `test_create_user`.

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
file, so modify `django_react_users_tutorial/urls.py` to be like the following:

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
password = serializers.CharField(min_length=8, write_only=True)
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

## User Registration - Errors

So, we have a basic version of user registration working, but there's one
problem. We're assuming that all input is valid input from the get-go. When it
comes to invalid inputs, we can have the following invalid state for each input:

- Username
  - Username already exists
  - Username not provided
  - Username too long
- Password
  - Password not provided
  - Password too short
- Email
  - Email already taken
  - Email not provided
  - Invalid email format

 Now that we know what we need to be wary of, let's start off with adding in tests for the `password` states.

```python
...

class AccountsTest(APITestCase):
    ...

    def test_create_user_with_short_password(self):
        """
        Ensure user is not created for password lengths less than 8.
        """
        data = {
                'username': 'foobar',
                'email': 'foobarbaz@example.com',
                'password': 'foo'
        }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['password']), 1)

    def test_create_user_with_no_password(self):
        data = {
                'username': 'foobar',
                'email': 'foobarbaz@example.com',
                'password': ''
        }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['password']), 1)

```
Running `python manage.py test` will provide us with the following output.

```
AssertionError: Expected a `Response`, `HttpResponse` or `HttpStreamingResponse` to be returned from the view, but received a `<type 'NoneType'>`
```

Let's tweak our `accounts/views.py` to return an HTTP response in the case of
invalid inputs, complete with the errors from the serializer.

```python
...

def post(self, request, format='json'):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            if user:
                return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

Running our handy test command again gives us the following output.

```
...
----------------------------------------------------------------------
Ran 3 tests in 0.110s

OK
```

Awesome. That wasn't too bad. Let's add in some more tests to
`accounts/tests.py` for username validations.

```python
# accounts/tests.py
...

class AccountsTest(APITestCase):
    ...

    def test_create_user_with_too_long_username(self):
        data = {
            'username': 'foo'*30,
            'email': 'foobarbaz@example.com',
            'password': 'foobar'
        }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['username']), 1)
    
    def test_create_user_with_no_username(self):
        data = {
                'username': '',
                'email': 'foobarbaz@example.com',
                'password': 'foobar'
                }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['username']), 1)

    def test_create_user_with_preexisting_username(self):
        data = {
                'username': 'testuser',
                'email': 'user@example.com',
                'password': 'testuser'
                }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['username']), 1)
```

Running `python manage.py test` again gives us this output.

```
.....F
======================================================================
FAIL: test_create_user_with_too_long_username (accounts.tests.AccountsTest)
----------------------------------------------------------------------
Traceback (most recent call last):
    self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
AssertionError: 201 != 400

----------------------------------------------------------------------
Ran 6 tests in 0.216s
```

Ruh-roh. Looks like we need to revisit our serializers again. Re-open
`accounts/serializers.py` and change the username field to have a `max_length` validation[^3].

```python
# accounts/serializers.py
...
username = serializers.CharField(
            max_length=32,
            validators=[UniqueValidator(queryset=User.objects.all())]
            )
...
```

Save this file and run your `manage.py test` again. 

```
......
----------------------------------------------------------------------
Ran 6 tests in 0.189s

OK
```

Wicked. Now lastly, let's add in tests for email validation back in
`accounts/tests.py`.

```python
...
class AccountsTestCase(APITestCase):
    ...

    def test_create_user_with_preexisting_email(self):
        data = {
            'username': 'testuser2',
            'email': 'test@example.com',
            'password': 'testuser'
        }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['email']), 1)

    def test_create_user_with_invalid_email(self):
        data = {
            'username': 'foobarbaz',
            'email':  'testing',
            'passsword': 'foobarbaz'
        }


        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['email']), 1)
    
    def test_create_user_with_no_email(self):
        data = {
                'username' : 'foobar',
                'email': '',
                'password': 'foobarbaz'
        }

        response = self.client.post(self.create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(len(response.data['email']), 1)
```

Running our `python manage.py test` command should return the following output:

```
.........
----------------------------------------------------------------------
Ran 9 tests in 0.265s

OK
```

It's lit! Now that that is all done and accounted for, let's just make sure that
tokens are created for the user upon registration. We'll need these tokens for
logging in the user.

## User Registration - Tokens

This is foreshadowing, but we're going to use a simple token-based
authentication scheme for our application. We want to return the token after
creating a new user so we can "log the user in". we're going to use DRF's built-in
`TokenAuthentication`[^4] method. Open up `django_react_users_tutorial/settings.py`
and add `rest_framework.authtoken` to `INSTALLED_APPS`. It should look like
this.

```python
INSTALLED_APPS = (
  ...,
  'rest_framework',
  'rest_framework.authtoken',
)
```

Make sure you run `python manage.py syncdb` after changing your settings, so the
Token column can be added to our database. Next, we have to configure the
`REST_FRAMEWORK` settings in `settings.py`, so add the following to your
`settings.py` file.

```python
REST_FRAMEWORK = {
  'DEFAULT_AUTHENTICATION_CLASSES': (
      'rest_framework.authentication.TokenAuthentication',
    )
}
```

**Important Note:** IF you are deploying to Apache using mod_wsgi, make sure you
configure Apache to allow the Authorization header with `WSGIPassAuthorization`.

```
# this can go in either server config, virtual host, directory or .htaccess
WSGIPassAuthorization On
```

Next, we should modify our `test_create_user` method in `accounts/tests.py`
because we want to create and include the Token upon successful registration of
a user. 

```python
...
from rest_framework.authtoken.models import Token

class AccountsTest(APITestCase):
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
        user = User.objects.latest('id')
        ...
        token = Token.objects.get(user=user)
        self.assertEqual(response.data['token'], token.key)
```

Notice how we imported the `Token` model from `rest_framework.authtoken.models`.
Let's run `manage.py test` and see the output from that.

```
E........
======================================================================
ERROR: test_create_user (accounts.tests.AccountsTest)
----------------------------------------------------------------------
Traceback (most recent call last):
...
DoesNotExist: Token matching query does not exist.

----------------------------------------------------------------------
Ran 9 tests in 0.261s

FAILED (errors=1)
```

Oh boy. Let's get this test passing, shall we? Let's revisit our `views.py` file
in `accounts` and modify it to create a token after a successful
registration[^5].

```python
... # code leftout for brevity
from rest_framework.authtoken.models import Token

class UserCreate(APIView):
    """ 
    Creates the user. 
    """

    def post(self, request, format='json'):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            if user:
                token = Token.objects.create(user=user)
                json = serializer.data
                json['token'] = token.key
                return Response(json, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

Running our `manage.py test` commmand one more time should have all of the tests
passing again. Boom, we've finished the back-end portion of the user
registration. In the next tutorial, I'll show you how to connect this to React
and Redux. Feel free to check out the relevant GitHub branch for this part of
the tutorial [here](https://github.com/iheanyi/django-react-redux-users-tutorial/tree/django-registration).

[^1]: The latest version of Django is 1.9 at the time of this tutorial. Also, make sure you are using [virtualenv](https://virtualenv.readthedocs.org/en/latest/) for this project.
[^2]: Django Rest Framework.
[^3]: To me, 32 characters is good enough of a max length for usernames. Feel free to use another length.
[^4]: http://www.django-rest-framework.org/api-guide/authentication/#tokenauthentication
[^5]: The official Django Rest Framework documents suggests to use [signals](http://www.django-rest-framework.org/api-guide/authentication/#generating-tokens) for creating tokens, but they aren't my preference. 
