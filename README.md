# SimpleCache

A simple gem that implements a filesystem based download caching system. 

## Installation

Add this line to your application's Gemfile:

    gem 'simple_cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_cache

## Usage

First require it in your code:

```ruby
require 'simple_cache'
```

Then create a cacher with a caching directory: 

```ruby
cacher = SimpleCache::Cacher.new('/tmp/caches')
```

To downoad the file at `url`, caches it as `key`, and get the content, use `retrieve`: 

```ruby
content = cacher.retrieve(url, key)
```

For example: 

```ruby
content = cacher.retrieve('http://google.com', 'google_front_page')
```

If you want to retrieve an url, but would not be happy with any data that had been cached more than an hour ago, you can specify an expiration in seconds: 

```ruby
content = cacher.retrieve('http://google.com', 'google_front_page', expiration: 3600)
```

If you want to retrieve a previously cached link just by its cache key, you can use: 

```ruby
content = cacher.retrieve_by_key('google_front_page')
```

(Note that this will raise exception if the results are not cached or expired. )

If you do not need a custom cache key, you can simply use: 

```ruby
content = cacher.retrieve_by_url('http://google.com')
```

Also, `retrieve_by_key` and `retrieve_by_url` accepts the same hash options as `retrieve`. 

If you are done with all the cached results, you can clear the cache to free some disk space: 

```ruby
cacher.clear
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
