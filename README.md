# FollowableBehaviour

This is a fork from [acts_as_follower](https://github.com/tcocca/acts_as_follower) that has not been updated since 2017.

It's updated against Rails 8 and Ruby 3.1.

followable_behaviour is a gem to allow any model to follow any other model.
This is accomplished through a double polymorphic relationship on the Follow model.
There is also built in support for blocking/un-blocking follow records.

Main uses would be for Users to follow other Users or for Users to follow Books, etc...

(Basically, to develop the type of follow system that GitHub has)


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add followable_behaviour

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install followable_behaviour

## Usage

### Setup

Make your model(s) that you want to allow to be followed followable_behaviour, just add the mixin:
```ruby
  class User < ActiveRecord::Base
    ...
    followable_behaviour
    ...
  end

  class Book < ActiveRecord::Base
    ...
    followable_behaviour
    ...
  end
```

Make your model(s) that can follow other models follower_behaviour
```ruby
  class User < ActiveRecord::Base
    ...
    follower_behaviour
    ...
  end
```

---

### acts as follower methods

To have an object start following another use the following:
```ruby
  book = Book.find(1)
  user = User.find(1)
  user.follow(book) # Creates a record for the user as the follower and the book as the followable
```

To stop following an object use the following
```ruby
  user.stop_following(book) # Deletes that record in the Follow table
```

You can check to see if an object that follower_behaviour is following another object through the following:
```ruby
  user.following?(book) # Returns true or false
```

To get the total number (count) of follows for a user use the following on a model that follower_behaviour
```ruby
  user.follow_count # Returns an integer
```

To get follow records that have not been blocked use the following
```ruby
  user.all_follows # returns an array of Follow records
```

To get all of the records that an object is following that have not been blocked use the following
```ruby
  user.all_following
  # Returns an array of every followed object for the user, this can be a collection of different object types, eg: User, Book
```

To get all Follow records by a certain type use the following
```ruby
  user.follows_by_type('Book') # returns an array of Follow objects where the followable_type is 'Book'
```

To get all followed objects by a certain type use the following.
```ruby
  user.following_by_type('Book') # Returns an array of all followed objects for user where followable_type is 'Book', this can be a collection of different object types, eg: User, Book
```

There is also a method_missing to accomplish the exact same thing a following_by_type('Book') to make you life easier
```ruby
  user.following_users # exact same results as user.following_by_type('User')
```

To get the count of all Follow records by a certain type use the following
```ruby
  user.following_by_type_count('Book') # Returns the sql count of the number of followed books by that user
```

There is also a method_missing to get the count by type
```ruby
  user.following_books_count # Calls the user.following_by_type_count('Book') method
```

There is now a method that will just return the Arel scope for follows so that you can chain anything else you want onto it:
```ruby
  book.follows_scoped
```

This does not return the actual follows, just the scope of followings including the followables, essentially:
```ruby
  book.follows.unblocked.includes(:followable)
```

The following methods take an optional hash parameter of ActiveRecord options (:limit, :order, etc...)
```ruby
  follows_by_type, all_follows, all_following, following_by_type
```

---

### acts as followable methods

To get all the followers of a model that followable_behaviour
```ruby
  book.followers  # Returns an array of all the followers for that book, a collection of different object types (eg. type User or type Book)
```

There is also a method that will just return the Arel scope for followers so that you can chain anything else you want onto it:
```ruby
  book.followers_scoped
```
This does not return the actual followers, just the scope of followings including the followers, essentially:
```ruby
  book.followings.includes(:follower)
```

To get just the number of follows use
```ruby
  book.followers_count
```

To get the followers of a certain type, eg: all followers of type 'User'
```ruby
  book.followers_by_type('User') # Returns an array of the user followers
```

There is also a method_missing for this to make it easier:
```ruby
  book.user_followers # Calls followers_by_type('User')
```

To get just the sql count of the number of followers of a certain type use the following
```ruby
  book.followers_by_type_count('User') # Return the count on the number of followers of type 'User'
```

Again, there is a method_missing for this method as well
```ruby
  book.count_user_followers # Calls followers_by_type_count('User')
```

To see is a model that followable_behaviour is followed by a model that follower_behaviour use the following
```ruby
  book.followed_by?(user)
  # Returns true if the current instance is followed by the passed record
  # Returns false if the current instance is blocked by the passed record or no follow is found
```

To block a follower call the following
```ruby
  book.block(user)
  # Blocks the user from appearing in the followers list, and blocks the book from appearing in the user.all_follows or user.all_following lists
```

To unblock is just as simple
```ruby
  book.unblock(user)
```

To get all blocked records
```ruby
  book.blocks # Returns an array of blocked follower records (only unblocked) (eg. type User or type Book)
```

If you only need the number of blocks use the count method provided
```ruby
  book.blocked_followers_count
```

Unblocking deletes all records of that follow, instead of just the :blocked attribute => false the follow is deleted.  So, a user would need to try and follow the book again.
I would like to hear thoughts on this, I may change this to make the follow as blocked: false instead of deleting the record.

The following methods take an optional hash parameter of ActiveRecord options (:limit, :order, etc...)
```ruby
  followers_by_type, followers, blocks
```

---

### Follow Model

The Follow model has a set of named_scope's.  In case you want to interface directly with the Follow model you can use them.
```ruby
  Follow.unblocked # returns all "unblocked" follow records

  Follow.blocked # returns all "blocked" follow records

  Follow.descending # returns all records in a descending order based on created_at datetime
```

This method pulls all records created after a certain date.  The default is 2 weeks but it takes an optional parameter.
```ruby
  Follow.recent
  Follow.recent(4.weeks.ago)
```

Follow.for_follower is a named_scope that is mainly there to reduce code in the modules but it could be used directly.
It takes an object and will return all Follow records where the follower is the record passed in.

Note that this will return all blocked and unblocked records.
```ruby
  Follow.for_follower(user)
```
If you don't need the blocked records just use the methods provided for this:
```ruby
  user.all_follows
  # or
  user.all_following
```

Follow.for_followable acts the same as its counterpart (for_follower).  It is mainly there to reduce duplication, however it can be used directly.  It takes an object that is the followed object and return all Follow records where that record is the followable. Again, this returns all blocked and unblocked records.
```ruby
  Follow.for_followable(book)
```

Again, if you don't need the blocked records use the method provided for this:
```ruby
  book.followers
```
If you need blocked records only
```ruby
  book.blocks
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://gitlab.com/jbpfran/followable-behaviour.
