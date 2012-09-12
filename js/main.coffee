repo_link = (name) ->
  """<a href="http://github.com/#{name}" target="_blank">#{name}</a>"""

user_link = (username) ->
  """<a href="http://github.com/user/#{username}" target="_blank">#{username}</a>"""

github_event_types =
  "CommitCommentEvent":
    name: "Commit Comment"
  "CreateEvent":
    name: "Repo or Branch Created"
    render: (event) ->
      if event.payload.ref_type is "repository"
        """ #{user_link(event.actor.login)} created #{event.payload.ref_type} #{repo_link(event.repo.name)} """
      else
        """ #{user_link(event.actor.login)} created #{event.payload.ref_type} "#{event.payload.ref}" on #{repo_link(event.repo.name)} """

  "DeleteEvent":
    name: "Branch/Tag Deleted"
    render: (event) ->
      """ #{user_link(event.actor.login)} deleted #{event.payload.ref_type} "#{event.payload.ref}" on #{repo_link(event.repo.name)} """

  "DownloadEvent":
    name: "Download"
  "FollowEvent":
    name: "User Followed"
  "ForkEvent":
    name: "Fork"
  "ForkApplyEvent":
    name: "Fork Applied"
  "GistEvent":
    name: "Gist Created/Updated"
  "GollumEvent":
    name: "Wiki Updated"
  "IssueCommentEvent":
    name: "Issue Comment"
  "IssuesEvent":
    name: "Issue Opened/CLosed"
  "MemberEvent":
    name: "Collaborator Added"
  "PublicEvent":
    name: "Repo Open-Sourced"
  "PullRequestEvent":
    name: "Pull Request Opened/CLosed"
  "PullRequestReviewCommentEvent":
    name:  "Pull Request Comment"
  "PushEvent":
    name: "Push"
    render: (event) ->
      # todo: make this link to the correct commit
      """ #{user_link(event.actor.login)} pushed to #{repo_link(event.repo.name)} """

  "TeamAddEvent":
    name: "Team Added"
  "WatchEvent":
    name: "Repo Watched"
    render: (event) ->
      """ #{user_link(event.actor.login)} #{event.payload.action} watching #{repo_link(event.repo.name)} """

renderEvent = (event) ->
  if github_event_types[event.type]["render"]?
    github_event_types[event.type]["render"](event)
  else
    event.type

makeRequest = (params) ->
  $results = $("#results")
  $results.html('').addClass('loading')

  accounts = ""
  $("#accounts input:checked").each ->
    accounts += '"' + $(this).val() + '", '
  accounts = accounts.slice(0, -2)

  event_type_filter_yql = ""
  if $("#event-types input[type=checkbox]:not(:checked)").length > 0
    event_type_filter_yql = "AND json.type IN ("
    $("#event-types input[type=checkbox]:checked").each ->
      event_type_filter_yql += '"' + $(this).val() + '", '
    event_type_filter_yql = event_type_filter_yql.slice(0, -2)
    event_type_filter_yql += ")"

  yql = encodeURIComponent """
    USE "https://raw.github.com/gcb/yql.opentable/master/text.concat.xml" AS text.concat;

    SELECT json FROM json

    WHERE url in
      (SELECT text from text.concat
        WHERE text.key1 = "https://api.github.com/orgs/"
        AND text.key2 IN (#{accounts})
        AND text.key3 = "/events")

    #{event_type_filter_yql}

    | SORT(field="json.created_at", descending="true")
  """

  $.getJSON "http://query.yahooapis.com/v1/public/yql?q=#{yql}&format=json&_maxage=600", (json) ->
    for event in json.query.results.json
      $results.append """
        <li>#{renderEvent(event.json)}</li>
      """
    $results.removeClass('loading')

for key, val of github_event_types
  html = """
    <label class="checkbox">
      <input type="checkbox" value="#{key}" checked />
      #{val.name}
    </label>
  """
  $("#event-types > .accordion-inner").append(html)

$(document).on "change", "#accounts input[type=checkbox]", makeRequest
$(document).on "change", "#event-types input[type=checkbox]", makeRequest

$(document).on "click", ".toggle-all", ->
  checkboxes = $(this).parent().find(".accordion-inner input[type=checkbox]")
  checkboxes.attr('checked', (if (checkboxes.filter(":checked").length > 0) then false else true))
  makeRequest()

$ ->

  $.getJSON 'http://registry.usa.gov/accounts.json?service_id=github', (json) ->
    for account in json.accounts
      html = """
        <label class="checkbox">
          <input type="checkbox" value="#{account.account}" checked />
          #{account.account}
        </label>
      """
      $("#accounts > .accordion-inner").append(html)

    makeRequest()
