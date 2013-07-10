# Copyright 2002-2012 Rally Software Development Corp. All Rights Reserved.

dir = File.dirname(__FILE__)
app_path = File.expand_path("#{dir}/../")
unless $LOAD_PATH.include?(app_path)
  $LOAD_PATH.unshift app_path
end
app_path = File.dirname(__FILE__)
unless $LOAD_PATH.include?(app_path)
  $LOAD_PATH.unshift app_path
end
require 'scm_connector'
require 'perforce_connector'
require 'rally_proxy'
require 'scm_config_reader'
require 'obfuscate'
