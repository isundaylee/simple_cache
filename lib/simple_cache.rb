require "simple_cache/version"

module SimpleCache

  class Cacher
    require 'fileutils'
    require 'digest/md5'
    require 'curb'
    require 'progressbar'

    # Initializes the Cacher.
    #
    # @param cache_dir [String] The directory of the cache files.
    # @param options [Hash] Options for the Cacher.
    # @option options [Boolean] :store_urls (false) If the cacher should store urls associated with requested keys. This behavior defaults to false to save resources, but is especially useful when used with {#retrieve_by_key} alongside cache expiration, since if the urls are not stored, it would be impossible to refresh the cache given only the key. If this option is turned off, and an expired cache is requested with only key given, a RuntimeError would be raised.
    def initialize(cache_dir, options = {})
      @cache_dir = File.expand_path(cache_dir)
      @store_urls = options[:store_urls] || false

      @urls = {} if @store_urls

      FileUtils.mkdir_p(@cache_dir)
    end

    # Returns the contents at an URL. Uses cached results if available.
    #
    # @param url [String] The URL to be retrieved.
    # @param key [String] The cache key to be associated with the URL.
    # @param options [Hash] Additional options.
    # @option options [Boolean] :show_progress (false) If the cacher should display the downloading progress.
    # @option options [Fixnum, nil] :expiration (nil) Expiration time (in seconds) for the cached results. If this is set to nil, the cached results would never expire.
    def retrieve(url, key, options = {})
      # Defaults to hide caching progress.
      show_progress = options[:show_progress] || false

      # If expiration is set to nil, the cache never expires.
      # Otherwise, cache expires after expiration seconds.
      expiration = options[:expiration] || nil

      # If store_urls is enabled, try to retrieve the url.
      url ||= @urls[key] if @store_urls

      if cached?(key)
        if expired?(key, expiration)
          # Raise exception if url is not given and cannot be retrived.
          raise RuntimeError, 'Cannot retrieve by key. Cache expired but store_urls not enabled. ' unless url

          # Remove previous results.
          clear_cache(key)
          # Call self to re-retrieve.
          retrieve(url, key, options)
        else
          retrieve_cache(key)
        end
      else
        # Raise exception if url is omitted for first-time retrieval.
        raise RuntimeError, 'Cannot retrieve by key. No valid cache available. ' unless url

        download_to_cache(url, key, show_progress)
        @urls[key] = url if @store_urls
        retrieve_cache(key)
      end
    end

    # Returns the cached results associated with a cache key.
    #
    # @param key [String] The cache key.
    # @param options [Hash] Additional options.
    # @option options [Boolean] :show_progress (false) See {#retrieve}.
    # @option options [Fixnum, nil] :expiration (nil) See {#retrieve}.
    # @raise [RuntimeError] if the cached results have expired and the original urls cannot be retrieved because {:store_urls} is turned off. See {#initialize}.
    def retrieve_by_key(key, options = {})
      return retrieve(nil, key, options)
    end

    # Returns the cached results associated with a url. Use default cache key generated from url.
    #
    # @param url [String] The requested URL.
    # @param options [Hash] Additional options. See {#retrieve}.
    def retrieve_by_url(url, options = {})
      retrieve(url, Digest::MD5.hexdigest(url), options)
    end

    # Removes all cached results.
    def clear
      FileUtils.rm_rf(@cache_dir)
      FileUtils.mkdir_p(@cache_dir)
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

      def download_to_cache(url, key, show = false)
        # Create the progress bar if show_progress is on
        if show
          progress_bar = ProgressBar.new('Caching', 100, $stderr) if show
          progress_bar.bar_mark = '#'
        end

        # First download to a temporary file.
        curl_request = Curl.get(url) do |curl|
          curl.connect_timeout = 15
          if show
            curl.on_progress do |dt, dn, ut, un|
              prog = (dt == 0 ? 0 : 100 * dn / dt).to_i
              progress_bar.set(prog)
              true
            end
          else
            curl.on_progress { true }
          end
        end

        progress_bar.finish if show

        File.write(tmp_path(key), curl_request.body_str)

        # Rename it.
        FileUtils.mv(tmp_path(key), cache_path(key))
      end

      def cache_path(key)
        File.join(@cache_dir, key)
      end

      def tmp_path(key)
        File.join(@cache_dir, "#{key}.tmp")
      end

  end
end
