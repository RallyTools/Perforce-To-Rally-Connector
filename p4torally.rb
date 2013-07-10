# Copyright 2002-2012 Rally Software Development Corp. All Rights Reserved.

# Rally Connector for Perforce
# Use the comment field and enter text like "Fixed DE17" or "DE17 Fixed"
# rally change-commit //depot/... "ruby C:/"Program Files"/Perforce/Server/p4torally/scm/lib/perforce/p4torally.rb %changelist% %user%"

require 'rexml/document'
require File.dirname(__FILE__) + '/lib/perforce_library'

config = ScmConfigReader.new()
config.read_xml_config(File.dirname(__FILE__)+"/config.xml")
logger              = config.logger

rally_base_url      = config.rally_base_url
rally_workspace_name= config.workspace_name
rally_username      = config.user_name
rally_password      = config.password

if ARGV.length < 2
  raise("p4torally requires two arguments to execute: changeset_number and p4_user")
end

changeset_number = ARGV[0]
p4_user          = ARGV[1]

begin
  pc = PerforceConnector.new(config, {:user=>p4_user})

  if (pc.connect_to_rally(rally_base_url, rally_workspace_name, rally_username, rally_password))
    pc.execute(changeset_number)
  end

rescue
  puts "Perforce Connector failed due to error"
  if config.log_file_name != nil
    puts "Error was logged in log file"
  end
  logger.error("Perforce Connector failed due to error")
  logger.error($!)
end
