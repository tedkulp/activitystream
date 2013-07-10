ServiceBase = require '../base'
Event = require '../../models/event'
InstagramPost = require './instagram_post'

Event.registerEventType('InstagramPost', InstagramPost)

class InstagramService extends ServiceBase
  name: 'instagram'
  setup: (everyauth) ->
    `var that = this`

    everyauth.instagram
      .appId(process.env.INSTAGRAM_ID)
      .appSecret(process.env.INSTAGRAM_SECRET)
      .redirectPath('/')
      .scope('basic')
      .findOrCreateUser (session, accessToken, accessTokenExtra, user) ->
        promise = @Promise()

        that.setUserAttrsForService session.auth.userId, 'instagram',
          accessToken: accessToken
          userId: user.id
        , (err, data) ->
          return promise.fail(err) if err
          promise.fulfill(data)

        promise

  scrapeItems: (user) ->
    @getItems user, (err, data, pagination, limit) ->
      console.log err if err
      unless err
        # console.log data
        data.forEach (post) ->
          theModel = Event.getEventType('InstagramPost')
          theModel.findOne
            id: post.id
            userId: user.id
          .exec (err, data) ->
            console.log if err
            unless err or data
              post = new theModel.createObjectFromData(post, user)
              post.save (err) ->
                console.log err if err

  getItems: (user, callback) ->
    client = @createClient(user)
    if client
      client.user_media_recent 'self',
        count: 100
        min_timestamp: 1
      , (err, data, pagination, limit) ->
        callback(err, data, pagination, limit)

  createClient: (user) ->
    if user and user.services and user.services.instagram
      instagram = require('instagram-node').instagram()
      instagram.use
        access_token: user.services.instagram.accessToken
      instagram

module.exports = new InstagramService()
