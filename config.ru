# This file is used by Rack-based servers during development
require "bridgetown-core/rack/boot"

Bridgetown::Rack.boot

run RodaApp.freeze.app # see server/roda_app.rb