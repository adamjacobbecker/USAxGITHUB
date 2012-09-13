sisyphus = {}

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
      $results.append(githubSentences.convert(event.json))
    $(".timestamp").relatizeDate()
    $results.removeClass('loading')

for key, val of githubSentences.eventTypes
  html = """
    <label class="checkbox">
      <input type="checkbox" value="#{key}" name="[]" checked />
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
  sisyphus.saveAllData()

$(document).on "change keyup", "#search-input", ->
  $("#results .github-sentence-item").removeClass('hidden')
  searchTerm = $(this).val()
  if searchTerm
    $("#results .github-sentence-item").each ->
      if !$(this).html().match(searchTerm)
        $(this).addClass('hidden')

$ ->

  $.getJSON "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20json%20where%20url%20%3D%20%22http%3A%2F%2Fregistry.usa.gov%2Faccounts.json%3Fservice_id%3Dgithub%22&format=json&_maxage=3600&callback=", (json) ->
    for account in json.query.results.json.accounts
      html = """
        <label class="checkbox">
          <input type="checkbox" value="#{account.account}" name="[]" checked />
          #{account.account}
        </label>
      """
      $("#accounts > .accordion-inner").append(html)

    sisyphus = $("form").sisyphus()
    makeRequest()
