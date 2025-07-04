# Roda is a fast & lightweight web framework for Ruby
# Learn more at: http://roda.jeremyevans.net
#
# IMPORTANT: Use Roda directly, not Bridgetown::Rack::Roda (deprecated in 1.3.x)
class RodaApp < Roda
  plugin :bridgetown_server

  # Some Roda configuration
  plugin :default_headers,
    'Content-Type'=>'text/html',
    'X-Content-Type-Options'=>'nosniff',
    'X-Frame-Options'=>'deny',
    'X-XSS-Protection'=>'1; mode=block'

  route do |r|
    # Bridgetown site will be served automatically
    r.bridgetown
  end
end