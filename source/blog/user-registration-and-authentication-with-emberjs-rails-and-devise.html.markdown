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

By installing Guard, Guard Rails, and Guard Bundler, this does two things. First, whenever we make changes to any files within our Rails application, the server will automatically refresh to show these changes. Secondly, whenever we add new dependencies to our Gemfile, it will automatically execute "bundle install" and restart the server.

With everything installed, lets first start out by building out the  main functionality for our Rails back-end application for our application.

#### Building the Rails Back-End

While I won't necessarily go full-out TDD for the purposes of this tutorial, we will be using [rspec]() to write our tests. Open your ```Gemfile``` and add ```rspec-rails```:

```
...
group :development, :test do
  ...
  gem 'rspec-rails'
end
```

Now let's install ```rspec```:

```
bundle install
rails generate rspec:install
```

Before we begin building our API, let's add the following to our Gemfile.

```
# rails/Gemfile

gem 'active_model_serializers', '0.8.3'
```

If you are using Rails 4.2.0, you must use version 0.8.3 of the gem. Make sure you run ```bundle install``` and install it. 

##### User Registration

Add the following to your Gemfile:

```
gem 'devise'
```

Run the ```bundle``` command to install it, then run the Devise generator:

```
rails generate devise:install
```

Make sure the database is created by running the following:

```
rake db:create
```

Then we can generate our ```User``` model by executing the following commands: 

```
rails generate devise User
rake db:migrate
```

Next, we're going to add an authentication token to our `User` model.

```
rails g migration AddAuthenticationTokenToUser authentication_token:string
rake db:migrate
```

This authentication token will be generated whenever the User is created and returned on login back to the user.

Before each new User is saved, we must ensure that the authentication token exists. Open `models/user.rb` and add the following lines to the model, below the devise modules:

```ruby

before_save :ensure_authentication_token

def ensure_authentication_token
	if authentication_token.blank?
		self.authentication_token = generate_authentication_token
	end
end


private
 def generate_authentication_token
   loop do
     token = Devise.friendly_token
     break token unless User.where(authentication_token: token).first
   end
end
```

In the end, your `models/user.rb` file should look like this:

```ruby
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  before_save :ensure_authentication_token

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  private
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end
```

What we are doing here is ensuring that whenever a new user is created (meaning registered), we would like to create a unique authentication token for them before they are saved into the database, handled by `before_save :ensure_authentication_token` callback. The `ensure_authentication_token` method will generate an authentication token if the user's authentication token does not exist.  The `generate_authentication_token` method generates a unique authentication token for the user.


Before we start creating the registration, we need to create a serializer for the `User`. We can do that with the following command:

```
rails g serializer user
```

Open `app/serializers/user_serializer.rb` and modify the attributes line to the following:

```
# app/serializers/user_serializer.rb

attributes :id, :email
```
Next, we will need to override the Devise registration and sessions controllers. Copy Devise controllers to your app by running the following command:

```
rails generate devise:controllers api/users
```

This will create a `users/` directory in `app/controllers/api`.

Open `config/routes.rb` and modify the line `devise_for :users` to the following:

```
devise_for :users, path: 'api/users', controllers: { sessions: "api/users/sessions", registrations: "api/users/registrations" }
```

This makes the Devise routes map to the `api` URL namespace, as namespace nesting for Devise is broken.


Next, open `app/controllers/users/registrations_controller.rb` and modify the `create` method to the following:

```ruby
 
skip_before_filter :verify_authenticity_token, :only => :create

def create
  @user = User.new(user_params)
  
  if @user.save
    sign_in @user
    json = ::UserSerializer.new(current_user).as_json
    json[:user].merge(token: current_user.authentication_token)
    render json: json, status: :created
  else
    render json: {errors: @user.errors.to_json}, status: :unauthorized
  end
```

We want to disable CSRF on `create` because we will be using an authentication token as the security measure.

Additionally, make sure you add the user parameters to the controller as well:

```ruby
private
  def user_params
    params.require(:user).permit(:email, :password)
  end
```

To test the functionality of our registrations controller, let's create a spec for it.

```
rails g rspec:controller api/users/registrations_controller
```

Before we start writing our tests, we need to make sure to add Devise to `spec/rails_helper.rb`. Open the file and add the following line:

` config.include Devise::TestHelpers, type: :controller`

Let's write our tests. Open the newly created file at ```spec/controllers/api/users/registrations_controller_controller_spec.rb``` and add the following lines of code.

```ruby
require 'rails_helper'

RSpec.describe Api::Users::RegistrationsController, :type => :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "POST users#sign_up" do

    context "valid user credentials" do
      before do
        post :create, user: {email: "foo@bar.com", password: "foofoobar"}
      end

      it "creates the user" do
        expect(response.created?).to eq true
      end

      it "logs in the user" do
        expect(subject.current_user.nil?).to eq false
      end
    end
  end

  context "user already created" do
    before do
      @user = User.create(email: "foo@bar.com", password: "foofoobar")

      post :create, user: {email: @user.email, password: @user.password}
    end

    it "does not create the user" do
      expect(response.unauthorized?).to eq true
    end

    it "should not log in the user" do
      expect(subject.current_user.nil?).to eq true
    end
  end
end
```

By running `rspec` from the CL, you should see four of the tests passing, with one pending from `user_spec.rb`. If you open the file and comment out the only line in its block, all the tests will now be passing.

From these tests, we are sending a POST request to the `users/registrations#create` method and ensuring that our controllers behave as expected. If there are valid credentials and email doesn't exist, we expect the user to be created and then signed in. Else, if the user already exists, then we should not create the user and not sign them in. 

With that, we have our user registration feature working!


