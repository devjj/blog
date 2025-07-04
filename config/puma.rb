# Puma configuration
#
# IMPORTANT: This file ensures Bridgetown runs on port 4000
# Without this, Puma defaults to port 9292

port ENV.fetch("PORT") { 4000 }
environment ENV.fetch("RACK_ENV") { "development" }

# Allow puma to be restarted by the "bridgetown start" command.
plugin :tmp_restart