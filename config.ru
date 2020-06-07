# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
require 'rack-timeout'



use Rack::Timeout, service_timeout: 500000, wait_timeout: 500000, wait_overtime: 500000

run Rails.application
