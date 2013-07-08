ServiceBase = require '../base'
Event = require '../../models/event'
CheckIn = require './check_in'

Event.registerEventType('CheckIn', CheckIn)

if process.env.SERVICE_URL
  foursquareUrl = process.env.SERVICE_URL + "/auth/foursquare/callback"
else
  foursquareUrl = null

config =
  'secrets':
    'clientId': process.env.FOURSQUARE_ID || ''
    'clientSecret': process.env.FOURSQUARE_SECRET || ''
    'redirectUrl': foursquareUrl || process.env.FOURSQUARE_REDIRECT_URL || 'http://localhost:5000/auth/foursquare/callback'

foursquare = require('node-foursquare')(config)

class FoursquareService extends ServiceBase
  name: 'foursquare'
  setup: (everyauth) ->
    `var that = this`

    everyauth.foursquare
      .appId(process.env.FOURSQUARE_ID)
      .appSecret(process.env.FOURSQUARE_SECRET)
      .redirectPath('/')
      .findOrCreateUser (session, accessToken, accessTokenSecret, user) ->
        promise = @Promise()

        that.setUserAttrsForService session.auth.userId, 'foursquare',
          accessToken: accessToken
          accessTokenSecret: accessTokenSecret
          userId: user.id
        , (err, data) ->
          return promise.fail(err) if err
          promise.fulfill(data)

        promise

  scrapeItems: (user) ->
    @getCurrentUser user, (err, currentUser) =>
      console.log err if err
      unless err
        @getCheckins user, (err, data) ->
          console.log err if err
          unless err
            data.checkins.items.forEach (check_in) ->
              theModel = Event.getEventType('CheckIn')
              theModel.findOne
                id: check_in.id
                userId: user.id
              .exec (err, data) ->
                console.log err if err
                unless err or data
                  image = new theModel check_in
                  image.userId = user.id
                  image.foursquare_user_id = currentUser.user.contact.twitter || currentUser.user.id
                  image.full_name = currentUser.user.firstName + " " + currentUser.user.lastName
                  image.created_at = new Date(parseInt(check_in.createdAt) * 1000)
                  image.venue_name = check_in.venue.name
                  image.venue_url = check_in.venue.canonicalUrl
                  image.save (err) ->
                    console.log err

  getCurrentUser: (user, callback) ->
    foursquare.Users.getUser 'self', user.services.foursquare.accessToken, (err, data) ->
      callback(err, data)

  getCheckins: (user, callback) ->
    foursquare.Users.getCheckins null,
      limit: 100
    , user.services.foursquare.accessToken, (err, data) ->
      callback(err, data)

module.exports = new FoursquareService()
