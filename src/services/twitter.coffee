ServiceBase = require './base'
Event = require '../models/event'

twitter = require 'ntwitter'
_       = require 'underscore'

class TwitterService extends ServiceBase
  name: 'twitter'
  setup: (everyauth) ->
    `var that = this`
    everyauth.twitter
      .consumerKey(process.env.TWITTER_KEY)
      .consumerSecret(process.env.TWITTER_SECRET)
      .redirectPath('/')
      .findOrCreateUser (session, accessToken, accessTokenSecret, user) ->
        promise = @Promise()

        that.setUserAttrsForService session.auth.userId, 'twitter',
          token: session.auth.twitter.token
          tokenSecret: session.auth.twitter.tokenSecret
          accessToken: accessToken
          accessTokenSecret: accessTokenSecret
        , (err, data) ->
          return promise.fail(err) if err
          promise.fulfill(data)

        promise

  scrapeItems: (user) ->
    @getTweets user, (err, data) ->
      console.log err if err
      unless err
        data.forEach (tweet) ->
          theModel = Event.getEventType('Tweet')
          theModel.findOne
            id: tweet.id_str
            userId: user.id
          .exec (err, data) ->
            console.log err if err
            unless err or data
              tweetObj = theModel.createObjectFromData(tweet, user)
              tweetObj.save (err) ->
                console.log err

  getTweets: (user, callback) ->
    client = @createClient(user)
    client.getUserTimeline
      include_entities: 1
      count: 100
    , (err, data) ->
      callback(err, data)
  createClient: (user) ->
    if user and user.services and user.services.twitter
      new twitter
        consumer_key: process.env.TWITTER_KEY
        consumer_secret: process.env.TWITTER_SECRET
        access_token_key: user.services.twitter.accessToken
        access_token_secret: user.services.twitter.accessTokenSecret

module.exports = new TwitterService()
