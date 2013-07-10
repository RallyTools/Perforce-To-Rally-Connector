PerforceConnector
=================

Perforce Installation & User Guide

Perforce Connector is available on an as-is basis. Rally does not provide official support for this connector.

Revision history:

3.7 - enhancements:
Now use rally_api instead of rally_rest_api
2.2.0 - enhancements:
added mapping Git user email to Rally username on Changeset object
added ability to specify a prefix (https or http) on <SourceControlUrl>
2.1.0 - enhancements:
added mapping Perforce author to Rally user on Changeset object
added instructions on running connector as background process for optimal performance
2.0.0 - added the new Source Code objects in Rally.
1.0.3 - for consistency, renamed root directory from RallyToP4 to P4ToRally.
1.0.2 - added support of Ruby 1.9.1; fix for Rally states not being cached; other minor bug fixes.
1.0.0 - Original version.
Introduction

The Rally Connector for Perforce inspects the contents of a check-in comment and creates a changeset in Rally associated to the Rally artifact, creates changes for each affected file, and optionally updates the state of the Rally artifact. For example, if a developer checks in two files with the commit message "Fixed DE17", the Perforce Connector would create a changeset for the check-in revision, create two change objects for the affected files, link the changeset to the defect, and set the state of defect 17 as fixed.

The diagram below shows the objects that are created/modified when a check-in occurs with a Rally ID (such as US123, DE17, TA123) in the commit message. No objects are created if the formatted ID in the change message is not found in Rally.

 scm
Features

The connector can link to and modify tasks, defects and user stories contained in Rally. To change the state of a Rally artifact enter the ID for the story followed by the state you wish to change in your commit message.
Example: "Extremely important fetching feature done. US123 Completed"

The connector makes the following changes to Rally:

Depending up the artifact type, the "status" field is changed to the new status specified in the check-in comment (note "Completed" in the above example). The "status" fields on the artifacts are:
Defect: The "State" field.
Story: The "ScheduleState" field.
Task: The "State" field.
Creates an SCMSystemRepository object if one does not exist in Rally based on the <SCMRepositoryName> value in the configuration file.
Creates a Changeset object in Rally associated to the artifact with message, revision, commit timestamp and URI populated. Note screenshot (click to enlarge):
artifact
Creates a Change object in Rally for each affected file associated to the changeset with action, filename path, base, extension and URI fields populated. Note screenshot:
changes
The connector automatically sets the ToDo value of a task to 0 if the commit message contains a task ID and a state of completed.

Software and hardware requirements

The following are the hardware and software requirements to install and run the Rally Connector for Perforce.

A Rally subscription. Most build and changeset data will not show in Rally until a workspace administrator enables the build and changeset flag by editing the workspace.
Access to your Perforce server.
The Ruby programming language and Ruby gems (libraries) installed.
The Ruby gem "rally_api".
This connector has been tested on Perforce 2009.1 only.
Installation

Basic installation steps

Install Ruby & the Rally Connector for Perforce code.
Setup the config.xml for Perforce.
Run the config_test.rb to validate the config file is setup correctly.
Setup p4torally.rb to be executed by the Perforce trigger.
(Optional) If your site uses a proxy server to access Rally, you will need to set the http_proxy environment variable. To accomplish this on Windows 7:

Click on Start, right-click on Computer, select Properties
Click on Advanced system settings
In the new "System Properties" window, click on Environment Variables...
A new window opens titled "Environment Variables", under "System variables", click on New...
In the window titled "New System Variables", enter http_proxy in the "Variable name:" field, and enter your proxy's full HTTP Url in the Variable value: field (should be something like http://www-cache:8000)
Click OK (3 times) to save and exit this process.
You may need to restart your system in order for the change to take effect.
Note on upgrade process: If you are using a pre-2.0 version of the connector and wish to upgrade to 2.0, backup your config.xml file and then follow the installation instructions outlined below. If you plan to use your old config.xml file once you extract the contents of the new zip, add an <SCMRepositoryName> element to your config.xml and set it to the name of the SCMRepository you wish to create in Rally. The <SCMRepositoryName> element is a required. Additionally, you will need to download the rally_api gem by typing the command "gem install rally_api" from the command line. Optionally, to map authors to Rally changesets, add a <UserDomain> element to your config.xml file and set it to the email domain for your company (something like mydomain.com).
Install Ruby and the Rally Connector to Perforce

Install the Ruby programming language. Make sure the user running your Perforce server is given access to the Ruby installation.
Install the 3 required Ruby Gems: builder, rally_api and httpclient by entering the following from a command window (answer yes to any questions about installing required dependencies):
Command:
        gem  install  rally_api  httpclient

Sample output (the versions may vary):
        Fetching: httpclient-2.3.3.gem (100%)
        Fetching: rally_api-0.9.5.gem (100%)
        Successfully installed httpclient-2.3.3
        Successfully installed rally_api-0.9.5
        Successfully installed httpclient-2.3.3
        3 gems installed
        Installing ri documentation for httpclient-2.3.3...
        Installing ri documentation for rally_api-0.9.5...
        Installing ri documentation for httpclient-2.3.3...
        Installing RDoc documentation for httpclient-2.3.3...
        Installing RDoc documentation for rally_api-0.9.5...
        nstalling RDoc documentation for httpclient-2.3.3...
If you are using a proxy, add -p http://proxyhost:portnumber to the command line.
Save the RallyConnectorForP4-x-x.zip file locally (on your machine) into the directory where you want to install the connector. Navigate to this install directory and extract the RallyConnectorForP4-x.x.zip file you just saved.
Setup the configuration file

Edit and save the config.xml file, entering the appropriate values between each begin and end tag.

Set <RallyUserName> to the Rally user's login name you want to use for the updates in Rally.
Set <RallyPassword> to the Rally user's password. The first time the connector runs, it will encode your password and re-write (update) the XML file for added security.
Set <RallyBaseUrl> to the URL you use to log into Rally. For most users, the expected URL is rally1.rallydev.com or trial.rallydev.com.
Set <RallyWorkspaceName> to the name of the Rally Workspace where you want to update artifacts.
Set <SourceControlUrl> the URL you use to reference the Perforce web UI. For most users, this URL is similar to perforce.company.com:8080. Defaults to "http://" for the prefix.
Set <RallySCMRepositoryName> to any name of your choosing for the Rally SCMRepository object. The first time the connector runs, the connector automatically creates a new Rally SCMRepository object with Name set to the user specified name.
Set <UserDomain> to your company domain name such as acme.com. This tag determines what Rally user is used to populate the author field when creating the changeset object.
Optional - Set <CommitterUserLookupField> to a field name on the User Object in Rally. This will tell the connector to look up the commit user's name via that User Object field in Rally and to link the changeset Author to a user in Rally. For example, committer is user123 and the Rally user is user@rallydev.com with MiddleName set to user123. Note: If no users are found and the UserDomain element is set, the lookup will also try that association.
If set, the connector will lookup the Rally user based on the map to the Perforce user name. For example, myuser@domain.com username in Rally → myuser Perforce user name .

If not set, the connector will lookup the Rally user based on the Perforce user email. For example, myuser@domain.com username in Rally → myuser@domain.com Perforce user email.

The <Prefixes> element is used to specify any custom prefixes you have specified for your artifacts:

<Defect> This element is used to specify the prefix you use for defect artifacts.
<Story> This element is used to specify the prefix you use for story artifacts.
<Task> This element is used to specify the prefix you use for task artifacts.
Example config.xml file:

<Config>
   <RallyUserName>email@domain.com</RallyUserName>
   <RallyPassword>MyPassword</RallyPassword>
   <RallyBaseUrl>rally1.rallydev.com</RallyBaseUrl>
   <RallyWorkspaceName>MyWorkspace</RallyWorkspaceName>
   <SourceControlUrl>localhost:8080</SourceControlUrl> 
   <RallySCMRepositoryName>MyPerforceRepository</RallySCMRepositoryName>
   <UserDomain>domain.com</UserDomain>
   <CommitterUserLookupField>MiddleName</CommitterUserLookupField>
   <Prefixes>
      <-- This section is for specifying if you have configured
         Rally to use custom prefixes for the FormattedID's.
         NOTE: If your custom prefix ends with a number,
               this connector will not function properly.
     -->
      <Defect>DE</Defect>
      <Story>US</Story>
      <Task>TA</Task>
   </Prefixes>
   <Log>
      <FileName>Rally_Connector_Error.log</FileName>
      <Level>0</Level>
   </Log>
</Config>
After the first check-in comment which includes a Rally ID, the connector will rewrite the config.xml file to include the allowed state values for User Stories, Defects and Tasks. This will happen automatically as long as the connector script has write access to the file. This re-write will also add the <CachedStates> element to the file.

The <CachedStates> content in the config.xml file can remain untouched unless your Rally administrator modifies the allowed state values for User Stories and/or Defects. To force the next run of the connector to update the values stored in the config.xml file, modify it by deleting the text from the <CachedStates> tag to the closing tag </CachedStates>. The <CachedStates> content will be functionally equivalent to the following:

<CachedStates>
   <DefectStates>
      <!-- State field on the Defect artifact.-->
      <State>Pre-test</State>
      <State>Submitted</State>
      <State>Open</State>
      <State>Fixed</State>
      <State>Closed</State>
      <State>Post-test</State>
   </DefectStates>
   <HierarchicalRequirementStates>
      <!-- ScheduleState field on the User Story artifact.-->
      <State>Pre-story</State>
      <State>Defined</State>
      <State>In-Progress</State>
      <State>Completed</State>
      <State>Accepted</State>
      <State>Post-story</State>
   </HierarchicalRequirementStates>
   <TaskStates>
      <!-- State field on the Task artifact.-->
      <State>Defined</State>
      <State>In-Progress</State>
      <State>Completed</State>
   </TaskStates>
</CachedStates>
Test the configuration file

To test the config.xml file for completeness, issue this command:

ruby  config_test.rb
The above script will test the network settings and the connection information in your config.xml file. The output from the command should be:

1. Log file write Passed.
2. Rally Url Passed
3. Successfully connected to Rally
4. Rally Workspace found
5. Email Validation Passed
Setup Perforce trigger

The Perforce change-commit trigger is set up so the Rally connector process runs in the background for optimal performance. After the developer checks in code, the Rally connector immediately runs and updates the appropriate objects in Rally without the developer having to wait for the Rally web services requests to complete. Consequently, check the Rally log file for any errors.

Setting up the change-commit trigger on Unix:

The steps below assume all files are saved in the /opt/integrations directory. Your file paths may vary depending on your installation.

Create a shell script called RallyWrapper.sh that contains the command to run the p4torally.rb script. This command runs the process in the background and redirects standard error to the Rally_Connector_Error.log file. Ensure you specify the full path to Ruby and the p4torally.rb file. Example:
#!/usr/bin/ruby
cd /opt/integrations/P4ToRally/
./p4torally.rb  $1  $2  >  ./Connector.log  2>&1
Verify the RallyWrapper.sh file is executable by entering this command:
chmod  u+x  RallyWrapper.sh
Open the Perforce triggers file by typing "p4 triggers" and add the line below. Ensure you add at least one space to the beginning of the line so Perforce correctly interprets the trigger.
rally  change-commit //...  "/opt/integrations/P4ToRally/RallyWrapper.sh  %changelist%  %user%"
Save the p4 triggers file. The connector is now installed.
Setting up the change-commit trigger on Windows:

Create a VBScript (RunP4ToRally.vbs) which contains commands to run the connector in the background.
Set WshShell = WScript.CreateObject("WScript.Shell")
set args = WScript.Arguments
WshShell.Run("ruby C:\P4ToRally\p4torally.rb" &amp; " " &amp; args(0) &amp; " " &amp; args(1))
Create a batch file (RallyWrapper.bat) which contains commands to run the VBScript.
C:\P4ToRally\RunP4ToRally.vbs  %1  %2
From the start menu, select Run.
Enter p4 triggers into the text box.
On the bottom of the file that opens, add this line under the word Triggers:
rally  change-commit  //depot/...  "C:\P4ToRally\RallyWrapper.bat  %changelist%  %user%"
Save the p4 triggers file. The connector is now installed.
Tips

Why are changesets not displaying in Rally?
Verify your Workspace administrator has selected the Enable Build and Changeset option on the Edit Workspace configuration pop-up and verify there are no unexpected messages in the Rally_Connector_Error.log file. No errors are written to the console.
Debug output
You can change the level of logging from the connector by including the following information in your configuration file:
<Log>
    <FileName>Rally_Connector_Error.log</FileName>
    <Level>0</Level>
</Log>
Log level 0 will produce the maximum amount of output, with log level 5 producing the least. These levels are documented at http://corelib.rubyonrails.org/classes/Logger/Severity.html:

DEBUG   = 0
INFO    = 1
WARN    = 2
ERROR   = 3
FATAL   = 4
UNKNOWN =   5
Under the hood of the Perforce connector
Here are some notes about the internal workings of Rally's Perforce connector.
The PERFORCE source control system (SCM) allows developers to perform "checkins" of source modules (like most SCM's allow). These checkins can automatically issue "triggers", which are basically external user-written scripts invoked by Perforce.

Most of the internal workings of the connector is done via five files as outlined below. Typically all these files are installed into some working directory where the user will be managing the connector. This should not be in the Perforce install directory, but rather in a working directory of the user. Please note there are special considerations to take into account if the pathname to this directory contains spaces. See WARNING(s) below for an example.
The "Triggers:" file:
A temporary "Triggers:" file, with a name like t2566t86.tmp, maintained by Perforce, which will invoke the batch file RallyWrapper.bat (described next). This "Triggers:" file can be edited from an MS-DOS command window by entering the command:
p4  triggers
The above command will open a notepad window to the TMP file named something like t2566t86.tmp and the last three lines should look something like this:
Triggers:
        rally change-commit //
        depot/... "C:\Docume~1\Administrator\JPKoleP4\RallyWrapper.bat %changelist% %user%"
WARNING: Note that we did not use the text string "Documents and Settings" in the path name above as the embedded spaces cause parsing issues. Instead we used the "DOS 8.3 filename format" (http://en.wikipedia.org/wiki/8.3_filename).
The "RallyWrapper.bat" file:
This BAT file is invoked by the Perforce system when the user performs a checkin (because it is called out in the "Triggers:" file mentioned in the previous step). It will invoke a Visual Basic Script named RunP4ToRally.vbs, with 2 arguments: the first is the commit ID and the second is the Rally user name. Typically this BAT files contains the following line:
C:\Docume~1\Administrator\JPKoleP4\RunP4ToRally.vbs %1 %2
WARNING: Note that we did not use the text string "Documents and Settings" in the path name above as the embedded spaces cause parsing issues. Instead we used the "DOS 8.3 filename format" (http://en.wikipedia.org/wiki/8.3_filename). As a method of debugging, we could just omit the VBS step and invoke the Ruby script (file 4 below) straight from this file (we only use VBS so the task will run in the background). For debugging, one could put this line in the file instead if it helps:
￼C:\Ruby19\bin\ruby.exe C:\Docume~1\Administrator\JPKoleP4\p4torally.rb %1 %2
The "RunP4ToRally.vbs" file:
The VBS file which actually invokes Rally's Ruby script called p4torally.rb in the background (which is why we use the VBS system). This script (mentioned in the previous file) contains three lines as follows:
Set WshShell = WScript.CreateObject("WScript.Shell")
set args = WScript.Arguments
WshShell.Run("C:\Ruby19\bin\ruby.exe C:\Docume~1\Administrator\JPKoleP4\p4torally.rb" & " " & args(0) & " " & args(1))
Note: If you wish to place comments in this script, the VBS comment character is an apostrophe (as in: '). For example:
' This is a comment line
' This is also
The "p4torally.rb" file:
This is the Rally-to-Perforce connector code written in Ruby which communicates with Rally and creates changesets. This is basically the post-commit script invoked by RunP4ToRally.vbs mentioned in the previous file.
The "config.xml" file:
The XML configuration file which is read by the p4torally.rb Ruby code mentioned in the previous file. This file contains all the details needed to communicate with both the Perforce and Rally systems.
