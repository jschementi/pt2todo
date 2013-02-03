require 'rubygems'
require 'nokogiri'
require 'httpclient'
require 'open-uri'
require 'active_support/core_ext/object/blank'
require 'date'

require File.dirname(__FILE__) + '/config'

# Print out progress
$VERBOSE = false

# Get API URL for projects
def project_url project_id
    server = lookup_server_from_project(project_id)
    pivotal_url = server[:url]
    { :url => "#{pivotal_url}/projects/#{project_id}", :token => server[:token] }
end

# Get API URL for stories
def stories_url project_id
    server = lookup_server_from_project(project_id)
    pivotal_url = server[:url]
    { :url => "#{pivotal_url}/projects/#{project_id}/stories", :token => server[:token] }
end

# Given a project id, get the server's information
def lookup_server_from_project pid
    PT2TODO_CONFIG.each do |token, p|
        if p[:project_ids].include? pid
            return {:token => token, :url => p[:url], :project_ids => p[:project_ids], :append => p[:append]}
        end
    end
    return nil
end

# Owner of the stories to create TODOs for
OWNER = "Jimmy Schementi"

# Map Pivotal's story states to a more common task organization method.
@state_mapping = {
    :today => ['started', 'rejected'],
    :next => ['unstarted'],
    :someday => ['unscheduled'],
    :done => ['finished', 'delivered', 'accepted']
}

# Given a Pivotal Tracker `state`, give back a task prioritization.
def map_state(state)
    @state_mapping.each do |key, value|
        return key if value.include? state
    end
    :today
end

# Call the Pivotal Tracker API with the given `url`. This method provides the
# API Token as a HTTP Header.
def pivotal_tracker(server)
    clnt = HTTPClient.new
    clnt.get(server[:url], nil, { "X-TrackerToken" => server[:token] })
end

# Given a project's id (`pid`), get the project's name.
def project_name(pid)
    Nokogiri::HTML(pivotal_tracker(project_url(pid)).content).css('project > name').text.split(' ').join
end

# Given a project's id, and the body of the response from Pivotal Tracker's
# Stories API, return a list of strings in todo.txt format.
def my_todos(project_id, body)
    body.css('stories > story').select do |s|
        s.css('owned_by').text == OWNER
    end.inject({}) do |tasks, s|
        state = map_state s.css('current_state').text
        tasks[state] ||= []
        tasks[state] << s
        tasks
    end.map do |priority_group, stories|
        stories.map{|s| format_todotxt project_id, priority_group, s}
    end.flatten
end

# Formats a Pivotal Tracker story in the todo.txt format. Letter-based
# priorities are given to it depending on what the story's current status is.
# The story's labels and story type are todo.txt's contexts, while the story's
# project name is the todo's story. The URL of the story is also added to the
# todo, as well as a special @frompivotal context. The special context is used
# to make sure only todos from pivotal are modified when doing future imports
# from Pivotal.
def format_todotxt(project_id, priority_group, story)
    task_priority =
        case priority_group
        when :today   then "(A)"
        when :next    then "(B)"
        when :someday then "(C)"
        end
    done = task_priority.nil?
    # TODO: escape newlines...
    title = story.css('name').text
    url = story.css('url').text
    story_id = story.css('id').text
    story_type = story.css('story_type').text
    labels = story.css('labels').text.split(',')

    d = Date.parse(story.css('updated_at').text)
    updated_at = d.strftime("%Y-%m-%d")

    pname = project_name(project_id)

    append = lookup_server_from_project(project_id)[:append]

    task = ""
    task << "x #{updated_at} " if done
    task << "#{task_priority} " unless task_priority.blank?
    task << title
    task << " @#{story_type}" unless story_type.blank?
    task << labels.map{|l| " @#{l}"}.join
    task << " +#{pname}" unless pname.blank?
    task << " url:#{url}" unless url.blank?
    task << " @frompivotal"
    task << " #{append}" unless append.blank?
    task
end

if __FILE__ == $0

    # Get a flattened list of each story in each project, converted to todo.txt
    # format.
    all_tasks = []
    PT2TODO_CONFIG.each do |token, server|
        server[:project_ids].each do |project_id|
            if $VERBOSE
                puts
                puts "#{project_name project_id} ..."
                puts
            end
            response = pivotal_tracker stories_url(project_id)
            body = Nokogiri::HTML response.content
            all_tasks << my_todos(project_id, body)
        end
    end
    all_tasks.flatten!
    all_tasks.sort!

    if $VERBOSE
        puts "DONE"
        puts
        puts
    end

    # Prints out all todos, useful for piping to other scripts.
    puts all_tasks.join("\n")

end
