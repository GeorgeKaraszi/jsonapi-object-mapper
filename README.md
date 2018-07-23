[![Gem Version](https://badge.fury.io/rb/jsonapi-object-mapper.svg)](https://badge.fury.io/rb/jsonapi-object-mapper) [![Build Status](https://travis-ci.com/GeorgeKaraszi/jsonapi-object-mapper.svg?branch=master)](https://travis-ci.com/GeorgeKaraszi/jsonapi-object-mapper) [![Maintainability](https://api.codeclimate.com/v1/badges/6eef293ed23cf92a4c1a/maintainability)](https://codeclimate.com/github/GeorgeKaraszi/jsonapi-object-mapper/maintainability)

# JsonapiObjectMapper

Deserialize's raw or pre-hashed JsonAPI objects into plan ruby objects as well as embeds any included relational resources.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi-object-mapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jsonapi-object-mapper

## Usage

```ruby
require "jsonapi-object-mapper"

class Photo < JsonAPIObjectMapper::Deserialize::Resource
  attribute :image
end

class User < JsonAPIObjectMapper::Deserialize::Resource
  # Embedding with another Resource class, will deserialize the `included` resource with the given class
  has_one :photo, embed_with: Photo
  
  # By default the value will be assigned whatever is located in the `included` selection. 
 # Otherwise basic relationship resource information will be added.
 #    - IE: { "type" = "friend", "id" = "10" }
  has_one :friend
  
  has_many :enemies, embed_with: User
  
  # This will accept the default value
  attribute :last_name
  
  # You can transform the setting value
  attribute :first_name do |attr_value|
    attr_value.upcase
  end
  
  # You can mass-assign attributes using the `attributes` method instead if blocks don't matter
  attributes :ssn, :passport, :more_person_info
end
  

user = User.call(json_payload) #=> <#User:123>

user.first_name #=> "FOOER"
user.last_name  #=> "Bar"
user.enemies    #=> <# JsonAPIObjectMapper::Deserialize::Collection #>

# If json API Payload is a collection of data points
users = User.call(json_payload) #=> <# JsonAPIObjectMapper::Deserialize::Collection #>

users.each do |user|
  user.first_name
  user.last_name
end

```

### Errors

```ruby

user = User.call(json_payload)

# Aliases: document_valid?
# Inverses: errors?, invalid?, document_invalid? 
user.valid?  #=> false
user.errors  #=> [<# OpenStruct title:..., detail: ..., source: {...}, ...>, ...]

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonapiObjectMapper project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/georgekaraszi@gmail.com/jsonapi_object_mapper/blob/master/CODE_OF_CONDUCT.md).
