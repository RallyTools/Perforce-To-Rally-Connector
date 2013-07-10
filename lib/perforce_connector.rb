# Copyright 2002-2012 Rally Software Development Corp. All Rights Reserved.

require 'cgi'
require 'perforce_library'

class PerforceConnector < SCMConnector

  P4_CONNECTOR_VERSION = "3.7"

  #http://localhost:8080/65?ac=10 gets the web page for changelist 65
  CHANGELIST_ACTION_CODE    = "ac=10"

  #http://localhost:8080//depot/main/ProjectX/Help/roadmap.html?ac=22
  FILE_REVISION_ACTION_CODE = "ac=22"

  #http://localhost:8080/bruno?ac=17 
  AUTHOR_ACTION_CODE        = "ac=17"

  def initialize (config, options)
    @perforce_user = options[:user] || raise(":user is required in PerforceConnector options ")
    @p4url = config.scm_url

    super(config)
  end

  def get_connector_name()
    return "Perforce"
  end

  def get_connector_version()
    return P4_CONNECTOR_VERSION
  end

  def get_commit_message()
    @raw_commit_message = `p4 describe -s #{@changeset_number}`
    if @raw_commit_message.empty?
      @logger.warn("Empty commit message for #{@changeset_number}")
    end
    @logger.debug("perforce_connector.get_commit_message# Commit message for #{@changeset_number}: #{@raw_commit_message}")
    return parse_commit_comment(@raw_commit_message)
  end

  def get_committer_email()
    p4_user_info  = `p4 user -o #{@perforce_user}`
    p4_user_email = p4_user_info.match(/[0-9A-Za-z\-_.]+@[0-9A-Za-z\-_\.]+\.[0-9A-Za-z\-_]+/) #looking for user@domain.com[.suffix]
    if !p4_user_email.nil?
      p4_user_email = p4_user_email[0]
    end
    return p4_user_email
  end

  def get_committer()
    p4_user_email = get_committer_email() if user_domain.nil?
    @logger.debug("perforce_connector.get_committer# returns #{@perforce_user}")
    return (p4_user_email.nil? ? @perforce_user : p4_user_email)
  end

  def get_affected_files()
    value = parse_affected_files(@raw_commit_message)
    @logger.debug("perforce_connector.get_affected_files# returns #{value}")
    return value

  end

  def parse_affected_files(raw_commit_message)
    @logger.debug("perforce_connector.parse_affected_files# #{raw_commit_message}")
    if (raw_commit_message.respond_to?(:encoding))
      logger.debug("raw_commit_message encoding : #{raw_commit_message.encoding.name}")
    end
    array = []
    count = 0
    raw_commit_message.split("\n").each do |line|
      if line.slice(0, 3) == "..."
        array[count] = line
        @logger.debug("File parsed from commit message: #{line}")
        count += 1
      end
    end
    @logger.debug("perforce_connector.parse_affected_files# returns #{array}")
    return array
  end

  def format_author(author)
    @logger.debug("perforce_connector.format_author# Author:#{author}")

    if @p4url != nil
      formatted_author = "#{@p4url}/#{author}?#{AUTHOR_ACTION_CODE}"
    else
      formatted_author = author
    end

    @logger.debug("perforce_connector.format_author# returns #{formatted_author}")
    return formatted_author
  end

  def get_changeset_uri(changeset)
    @logger.debug("perforce_connector.get_changeset_uri# Changeset#{changeset}")

    if !@p4url.nil?
      changeset_uri = "#{@p4url}/#{changeset}?#{CHANGELIST_ACTION_CODE}"
    else
      changeset_uri = changeset
    end

    @logger.debug("perforce_connector.get_changeset_uri# returns #{changeset_uri}")
    return changeset_uri
  end

  # Take a file line from the commit message and create the discussion line
  #http://localhost:8080//depot/main/ProjectX/Help/roadmap.html?ac=22
  #... //depot/doc2.txt#20 edit
  def get_change_uri(filename)
    @logger.debug("perforce_connector.get_change_uri# File#{filename}")

    if @p4url != nil
      formatted_file = "#{@p4url}#{filename.gsub(" ", "%20")}?#{FILE_REVISION_ACTION_CODE}"
    else
      formatted_file = filename
    end

    @logger.debug("perforce_connector.get_change_uri# returns #{formatted_file}")
    return formatted_file
  end


  def parse_commit_comment(commit_message)
    @logger.debug("perforce_connector.parse_commit_comment#")
    logger.debug("commit_message : |#{commit_message}|")
    return "" if commit_message.nil? or commit_message.empty?
    if (commit_message.respond_to?(:encoding))
      logger.debug("raw_commit_message encoding : #{commit_message.encoding.name}")
    end
    # cut off the list of files and the header for that section

    message = commit_message.slice(0, commit_message.index("Affected files ..."))
    #cut off the first line
    count   = 0
    comment = ""
    message.split("\n").each do |line|
      if count != 0
        comment += line
      end
      count += 1
    end
    @logger.debug("perforce_connector.parse_commit_comment# returns #{comment.strip}")
    return comment.strip
  end

  def construct_change_object(line)
    filepath = get_file_path(line)
    #return {:action => get_file_action(line),   :path_and_filename => filepath, 
    #          :base => get_file_base(filepath), :extension => get_file_extension(filepath), 
    #           :uri => get_change_uri(filepath)}
    return { 'Action'          => get_file_action(line),   
             'PathAndFilename' => filepath, 
             'Base'            => get_file_base(filepath), 
             'Extension'       => get_file_extension(filepath), 
             'Uri'             => get_change_uri(filepath)
           }
  end

  def get_file_path(line)
    start_index = line.index("//")
    end_index   = line.index("\#")
    file_name   = line.slice(start_index, end_index-start_index)
    return file_name
  end

  def get_file_action(line)
    split_line = line.split(" ")
    return split_line[split_line.length-1]
  end

end
