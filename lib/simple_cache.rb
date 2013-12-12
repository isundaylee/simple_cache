require "simple_cache/version"

module SimpleCache
  # Your code goes here...

  class Cacher
  	require 'fileutils'

  	def initialize(cache_dir)
  		@cache_dir = File.expand_path(cache_dir)

  		FileUtils.mkdir_p(@cache_dir)
  	end

  	def retrieve(url, key, options = {})
  		# Defaults to hide caching progress.
  		show_progress = options[:show_progress] || false

  		# If expiration is set to nil, the cache never expires.
  		# Otherwise, cache expires after expiration seconds.
  		expiration = options[:expiration] || nil

  		if cached?(key)
  			if expired?(key, expiration)
  				clear_cache(key)
  				# Call self to re-retrieve. 
  				retrieve(url, key, options)
  			else
  				retrieve_cache(key)
  			end
  		else
  			download_to_cache(url, key)
  			retrieve_cache(key)
  		end
  	end

  	private
  		def cached?(key)
  			File.exists?(cache_path(key))
  		end

  		def expired?(key, expiration)
  			expiration && (File.mtime(cache_path(key)) < Time.now - expiration)
  		end

  	  def clear_cache(key)
  	  	FileUtils.rm_f(cache_path(key))
  	  end

  	  def retrieve_cache(key)
  	  	File.open(cache_path(key)).read
  	  end

  	  def download_to_cache(url, key)
  	  	# First download to a temporary file. 
  	  	download(url, tmp_path(key))

  	  	# Rename it. 
  	  	FileUtils.mv(tmp_path(key), cache_path(key))
  	  end

  	  def download(url, path)
  	  	require 'open-uri'
  	  	File.write(path, open(url).read)
  	  end

  		def cache_path(key)
  			File.join(@cache_dir, key)
  		end

  		def tmp_path(key)
  			File.join(@cache_dir, "#{key}.tmp")
  		end

  end
end
