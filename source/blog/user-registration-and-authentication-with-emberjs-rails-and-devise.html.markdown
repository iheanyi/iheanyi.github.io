---
title: User Authentication with EmberJS, Rails, and Devise
date: 2015-01-28 19:21 UTC
tags:
published: false
---


In this tutorial, we will be creating an Ember application with user authentication and registration using a Ruby on Rails back-end with the [Devise] (https://github.com/plataformatec/devise) gem.

####Getting Setup

Before we begin developing, make sure that you have the following tools installed on your machine. 

*	Ruby 2.2.0
*	Rails 4.2.0
*	Node 0.10.35
*	npm 2.2
*	Ember-CLI 0.1.12
*	Postgres (for deploying to Heroku)


For this tutorial, versions at or above the following should suffice. For installing these tools, please refer elsewhere on the web.

Next, we will install `ember-cli`.

```bash
npm install -g ember-cli
```

Confirm that ember is installed by running ```ember --version```. You should see ```version: 0.1.12``` or higher.


##### Creating the Rails and Ember Apps
Change into the desired directory for your new project and then create the directory that will house our Rails and EmberJS applications.

```
mkdir ember_rails_auth
cd ember_rails_auth
```

Next, create an rvm gemset so we can sandbox our gem dependencies.

```
rvm gemset create ember_rails_auth
rvm gemset use ember_rails_auth
gem install rails
```

After that finishes, create a new Rails project, then rename it.

```
rails new ember_rails_auth -B -S -d postgresql
mv ember_rails_auth rails
```

And then the Ember project.

```
ember new ember_rails auth
mv ember_rails_auth ember
```

Your directory should now look like this.

```
ember_rails_auth
├── ember
└── rails
```

Confirm that the EmberJS app was successfully creatd:

``` 
cd ember
ember server	
```

If you visit ```http://localhost:4200``` and see "Welcome to Ember.js", you're good to go!

Change back into the ```ember_rails_auth``` directory, so we can make some modifications to our Rails application.

```
rm -rf rails/app/assets
```

Also, remove the following from ```rails/Gemfile```:

* coffee-rails
* jquery-rails
* turbolinks
* jbuilder

By making these modifications, we've removed the Asset Pipeline from our Rails application.

Let's change into the Rails directory and add some gems that will save us some time to our `Gemfile`.

```ruby
group :development do
  gem 'guard'
  gem  'guard-rails'
  gem  'guard-bundler'
end
```

Then let's install and add them by running the following commands:

```
bundle install
bundle exec guard init
```

By install Guard, Guard Rails, and Guard Bundler, this does two things. First, whenever we make changes to any files within our Rails application, the server will automatically refresh to show these changes. Secondly, whenever we add new dependencies to our Gemfile, it will automatically execute "bundle install" and restart the server.

With everything installed, lets first start out by building out the  main functionality for our Rails back-end application for our application.

#### Building the Rails Application

While I won't necessarily go full-out TDD for the purposes of this tutorial, we will be using [rspec]() to write our tests. Open your ```Gemfile``` and add ```rspec-rails```:

```
...
group :development, :test do
  ...
  gem 'rspec-rails'
end
```

If your server isn't running, run ```bundle install```to install the new gems. Then run the following:

```
rails generate rspec:install
```

This will generate the following files:

* rspec
* spec/rails_helper.rb
* spec/spec_helper.rb



#### Acknowledgements
[Stanley]() for helping me figure out how to do this in the first place.
[Dockyard]() for being a reference point on how to write a tutorial.


