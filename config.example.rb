TODOTXT = 'path/to/todo.sh'
TODOFILE = 'path/to/todo.txt'
DONEFILE = 'path/to/done.txt'
PT2TODO_CONFIG = {
    # API token for your Pivotal Tracker account
    '00000000000000000000000000000000' => {

        # URL for Pivotal Tracker (change if self-hosted)
        :url => 'https://www.pivotaltracker.com/services/v3',

        # List of project IDs to pull stories from:
        :project_ids => [
            1,
            2,
            3,
        ],

        # Optional: appends this string to each imported todo.
        # Note, each todo will always have the @frompivotal category,
        # and the +NameOfPivotalTrackerProject.
        :append => "@custom-category "
    },

    # Repeat the above sections if you have multiple
    # Pivotal Tracker accounts...
}
