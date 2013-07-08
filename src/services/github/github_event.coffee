mongoose = require 'mongoose'
moment = require 'moment'

module.exports = (ParentSchema) ->

  GithubEventSchema = ParentSchema.extend
    action:
      type: String
      default: "PushEvent"
    user_screen_name: String
    url: String
    description: String

  GithubEvent = mongoose.model 'GithubEvent', GithubEventSchema, 'events'

  GithubEvent.prototype.displayHtml = ->
    output = []
    output.push "<a class='event-user-name'>#{@user_screen_name}</a>"
    output.push "<a target='blank' href='#{@url}'>#{@description}</a>"
    output.push "<span class='event-date'>#{moment(@created_at).format('h:mm a')}</span>"
    output.join(' ')

  GithubEvent.prototype.origToJSON = GithubEvent.prototype.toJSON
  GithubEvent.prototype.toJSON = () ->
    json = @origToJSON.call(@)
    json.html = @displayHtml()
    json

  GithubEvent.createObjectFromData = (event, user) ->
    eventObj = new GithubEvent event
    eventObj.id = event.id
    eventObj.user_screen_name = event.actor.login
    eventObj.userId = user.id
    eventObj.action = event.type

    switch event.type
      when "PushEvent"
        eventObj.description = "pushed to #{event.payload.ref} at #{event.repo.name}"
        eventObj.url = "https://github.com/#{event.repo.name}/compare/#{event.payload.before}...#{event.payload.head}"
        eventObj
      when "ForkEvent"
        eventObj.description = "forked #{event.repo.name} to #{event.payload.forkee.full_name}"
        eventObj.url = event.payload.forkee.html_url
        eventObj
      when "PullRequestEvent"
        eventObj.description = "#{event.payload.action} pull request #{event.repo.name}##{event.payload.number}"
        eventObj.url = event.payload.pull_request.html_url
        eventObj
      when "WatchEvent"
        if event.payload.action == 'started'
          eventObj.description = "starred #{event.repo.name}"
        else
          eventObj.description = "unstarred #{event.repo.name}"
        eventObj.url = "https://github.com/#{event.repo.name}"
        eventObj
      when "IssueCommentEvent"
        eventObj.description = "commented on issue #{event.repo.name}##{event.payload.issue.number}"
        eventObj.url = "#{event.payload.issue.html_url}#issuecomment-#{event.payload.comment.id}"
        eventObj
      when "PublicEvent"
        eventObj.description = "open sourced #{event.repo.name}"
        eventObj.url = "https://github.com/#{event.repo.name}"
        eventObj
      when "DeleteEvent"
        null
      else
        console.log event
        null

  GithubEvent
