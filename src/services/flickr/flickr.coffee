ServiceBase = require '../base'
Event = require '../../models/event'
FlickrImage = require './flickr_image'

Event.registerEventType('FlickrImage', FlickrImage)

flickr = require('flickr').Flickr

class FlickrService extends ServiceBase
  name: 'flickr'
  setup: (everyauth) ->
    `var that = this`

    everyauth.flickr
      .consumerKey(process.env.FLICKR_KEY || '')
      .consumerSecret(process.env.FLICKR_SECRET || '')
      .redirectPath('/')
      .findOrCreateUser (session, accessToken, accessTokenSecret, user) ->
        promise = @Promise()

        that.setUserAttrsForService session.auth.userId, 'flickr',
          token: session.auth.flickr.token
          tokenSecret: session.auth.flickr.tokenSecret
          accessToken: accessToken
          accessTokenSecret: accessTokenSecret
          userId: user.user.id
        , (err, data) ->
          return promise.fail(err) if err
          promise.fulfill(data)

        promise

  scrapeItems: (user) ->
    @getPublicPhotos user, (err, data) ->
      console.log err if err
      unless err
        data.photos.photo.forEach (photo) ->
          theModel = Event.getEventType('FlickrImage')
          theModel.findOne
            id: photo.id
            userId: user.id
          .exec (err, data) ->
            console.log err if err
            unless err or data
              image = new theModel photo
              image.userId = user.id
              image.created_at = new Date(parseInt(photo.dateupload) * 1000)
              image.save (err) ->
                console.log err

  getPublicPhotos: (user, callback) ->
    client = @createClient(user)
    client.executeAPIRequest 'flickr.people.getPublicPhotos',
      user_id: user.services.flickr.userId
      extras: 'date_upload, path_alias'
    , true, (err, data) ->
      callback(err, data)

  createClient: (user) ->
    if user and user.services and user.services.flickr
      new flickr process.env.FLICKR_KEY, process.env.FLICKR_SECRET,
        oauth_token: user.services.flickr.accessToken
        oauth_token_secret: user.services.flickr.accessTokenSecret

module.exports = new FlickrService()
