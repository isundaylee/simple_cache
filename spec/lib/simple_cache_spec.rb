require_relative '../spec_helper'

module SimpleCache
	require 'fileutils'

	describe Cacher do
		before :each do
			@cache_path = '/tmp/simple_cache_test'
			@url_to_cache = 'http://nothing.com/'
			@key_to_cache = 'nothing'
			@content = 'content'

			# Clear the cache dir before each case.
			FileUtils.rm_rf(@cache_path)

			@cacher = Cacher.new(@cache_path)

			# Stubbing net requests
			stub_request(:any, @url_to_cache).to_return(body: @content)
		end

		describe 'initialize' do
			it "should create directory if not existing" do
				expect(File.exists?(@cache_path)).to be_true
			end
		end

		describe 'retrieve' do

			context "when never cached" do
				it "should return the correct value" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache)).to eq(@content)
				end

				it "should download once" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache)).to have_requested(:any, @url_to_cache).once
				end
			end

			context "when cached without expiration" do
				before { @cacher.retrieve(@url_to_cache, @key_to_cache) }

				it "should return the correct value" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache)).to eq(@content)
				end

				it "should only download once" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)).to have_requested(:any, @url_to_cache).once
				end
			end

			context "when cached with not-yet-expired expiration" do
				before { @cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100) }

				it "should return the correct value" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)).to eq(@content)
				end

				it "should only download once" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)).to have_requested(:any, @url_to_cache).once
				end
			end

			context "when cached with expired expiration" do
				before do 
					@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)
					Timecop.travel(Time.now + 3600)
				end 

				after { Timecop.travel(Time.now - 3600) }

				it "should return the correct value" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)).to eq(@content)
				end

				it "should download twice" do
					expect(@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)).to have_requested(:any, @url_to_cache).twice
				end
			end
		end

		describe "retrieve_by_key" do
			context "when the request is first-time" do
				it "should raise exception" do
					expect { @cacher.retrieve_by_key('none_existing') }.to raise_exception
				end
			end

			context "when the request has been validly cached" do
				before { @cacher.retrieve(@url_to_cache, @key_to_cache) }

				it "should return correct result" do
					expect(@cacher.retrieve_by_key(@key_to_cache)).to eq(@content)
				end
			end

			context "when the request has been cached and has expired" do
				before { Timecop.travel(Time.now + 3600) }

				after { Timecop.travel(Time.now - 3600) }

				context "when store_urls is enabled" do
					it "should return correct result" do
						@cacher2 = Cacher.new(@cache_path, store_urls: true)
						@cacher2.retrieve(@url_to_cache, @key_to_cache, expiration: 100)
						expect(@cacher2.retrieve_by_key(@key_to_cache, expiration: 100)).to eq(@content)
					end
				end

				context "when store_urls is not enabled" do
					it "should raise exception" do
						@cacher.retrieve(@url_to_cache, @key_to_cache, expiration: 100)
						expect { @cacher.retrieve_by_key(@key_to_cache, expiration: 100) }.to raise_exception
					end
				end
			end
		end
	end
end