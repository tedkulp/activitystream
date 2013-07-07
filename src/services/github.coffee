ServiceBase = require './base'
Event = require '../models/event'

githubApi = require 'github'

class GithubService extends ServiceBase
  name: 'github'
  setup: (everyauth) ->
    `var that = this`
    everyauth.github
      .appId(process.env.GITHUB_ID || '')
      .appSecret(process.env.GITHUB_SECRET || '')
      .redirectPath('/')
      .findOrCreateUser (session, accessToken, accessTokenExtra, user) ->
        promise = @Promise()

        that.setUserAttrsForService session.auth.userId, 'github',
          accessToken: accessToken
          userId: user.id
          userLogin: user.login
        , (err, data) ->
          return promise.fail(err) if err
          promise.fulfill(data)

        promise

  scrapeItems: (user) ->
    @getTweets user, (err, data) ->
      console.log err if err
      unless err
        data.forEach (githubEvent) ->
          theModel = Event.getEventType('GithubEvent')
          theModel.findOne
            id: githubEvent.id
            userId: user.id
          .exec (err, data) ->
            console.log err if err
            unless err or data
              githubObj = theModel.createObjectFromData(githubEvent, user)
              if githubObj
                githubObj.save (err) ->
                  console.log err

  getTweets: (user, callback) ->
    client = @createClient(user)
    client.events.getFromUserPublic
      user: user.services.github.userLogin
    , (err, data) ->
      callback(err, data)

  createClient: (user) ->
    if user and user.services and user.services.github
      github = new githubApi
        version: "3.0.0"
      github.authenticate
        type: "oauth"
        token: user.services.github.accessToken
      github

module.exports = new GithubService()
