#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'time'

def handler(event:, context:)
  # Only run on successful deploy
  return { statusCode: 200, body: 'Not a deploy success event' } unless event['body']
  
  begin
    payload = JSON.parse(event['body'])
    return { statusCode: 200, body: 'Not a deploy success' } unless payload['state'] == 'ready'
    
    # Read latest post metadata
    meta_url = "#{payload['ssl_url']}/latest_post_meta.json"
    meta_response = Net::HTTP.get_response(URI(meta_url))
    
    return { statusCode: 404, body: 'No latest post meta found' } unless meta_response.code == '200'
    
    post_meta = JSON.parse(meta_response.body)
    
    # Check if we should syndicate to Bluesky
    return { statusCode: 200, body: 'Post opted out of Bluesky syndication' } unless post_meta['syndicate_to_bluesky']
    
    # Get Bluesky credentials from environment
    handle = ENV['BLUESKY_HANDLE']
    password = ENV['BLUESKY_APP_PASSWORD']
    
    return { statusCode: 400, body: 'Missing Bluesky credentials' } unless handle && password
    
    # Create session with Bluesky
    session = create_bluesky_session(handle, password)
    return { statusCode: 401, body: 'Failed to authenticate with Bluesky' } unless session
    
    # Check if post already exists
    if post_already_exists?(session, handle, post_meta['url'])
      return { statusCode: 200, body: 'Post already syndicated to Bluesky' }
    end
    
    # Create the post
    post_text = "#{post_meta['title']}\n\n#{post_meta['url']}"
    result = create_bluesky_post(session, post_text)
    
    if result
      { statusCode: 200, body: 'Successfully posted to Bluesky' }
    else
      { statusCode: 500, body: 'Failed to post to Bluesky' }
    end
  rescue => e
    { statusCode: 500, body: "Error: #{e.message}" }
  end
end

def create_bluesky_session(handle, password)
  uri = URI('https://bsky.social/xrpc/com.atproto.server.createSession')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = {
    identifier: handle,
    password: password
  }.to_json
  
  response = http.request(request)
  
  if response.code == '200'
    JSON.parse(response.body)
  else
    nil
  end
end

def post_already_exists?(session, handle, url)
  uri = URI("https://bsky.social/xrpc/com.atproto.repo.listRecords")
  uri.query = URI.encode_www_form({
    repo: session['did'],
    collection: 'app.bsky.feed.post',
    limit: 50
  })
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{session['accessJwt']}"
  
  response = http.request(request)
  
  if response.code == '200'
    records = JSON.parse(response.body)
    records['records'].any? { |r| r['value']['text']&.include?(url) }
  else
    false
  end
end

def create_bluesky_post(session, text)
  uri = URI('https://bsky.social/xrpc/com.atproto.repo.createRecord')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{session['accessJwt']}"
  
  # Parse URLs from text and create facets
  facets = extract_url_facets(text)
  
  post_data = {
    repo: session['did'],
    collection: 'app.bsky.feed.post',
    record: {
      '$type': 'app.bsky.feed.post',
      text: text,
      createdAt: Time.now.utc.iso8601,
      facets: facets
    }
  }
  
  request.body = post_data.to_json
  
  response = http.request(request)
  response.code == '200'
end

def extract_url_facets(text)
  facets = []
  
  # Simple URL regex - matches http/https URLs
  url_regex = %r{https?://[^\s]+}
  
  text.scan(url_regex) do |url|
    match = Regexp.last_match
    byte_start = text[0...match.begin(0)].bytesize
    byte_end = text[0...match.end(0)].bytesize
    
    facets << {
      index: {
        byteStart: byte_start,
        byteEnd: byte_end
      },
      features: [
        {
          '$type': 'app.bsky.richtext.facet#link',
          uri: url
        }
      ]
    }
  end
  
  facets
end