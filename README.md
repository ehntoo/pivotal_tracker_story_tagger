pivotal_tracker_story_tagger
============================

A script to tag stories in Pivotal Tracker with sequential user-friendly short IDs.

Depends on three environment variables to function:

* PIVOTAL_TRACKER_PROJECT_ID - Your Pivotal Tracker project ID
* PIVOTAL_TRACKER_API_TOKEN - Your personal API token, found on your profile page
* PIVOTAL_TRACKER_STORY_PREFIX - The short code before the story number - e.g. "TLA-" would produce stories named "TLA-82 - Add the secret sauce to the frontpage"

Once all the vars are set up, usage is simple:
    ruby tagger.rb
