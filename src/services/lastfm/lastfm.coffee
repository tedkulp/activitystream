ServiceBase = require '../base'
Event = require '../../models/event'
Track = require './track'

Event.registerEventType('Track', Track)

config =
  api_key: process.env.LASTFM_KEY || ''
  secret: process.env.LASTFM_SECRET || ''

lastfmnode = require('lastfm').LastFmNode

class LastFmService extends ServiceBase
  name: 'lastfm'
  setup: (everyauth) ->
    `var that = this`

    everyauth.lastfm
      .appId(config.api_key)
      .appSecret(config.secret)
      .redirectPath('/')
      .entryPath('/auth/lastfm')
      .callbackPath('/auth/lastfm/callback')
      .findOrCreateUser (session, sessionToken, user) ->
        promise = @Promise()

        that.setUserAttrsForService session.auth.userId, 'lastfm',
          accessToken: sessionToken
          userId: user.session.name
        , (err, data) ->
          return promise.fail(err) if err
          promise.fulfill(data)

        promise

  scrapeItems: (user) ->
    @getRecentTracks user, (err, data) ->
      console.log err if err
      unless err
        data.recenttracks.track.forEach (track) ->
          theModel = Event.getEventType('Track')
          theModel.findOne
            id: track.mbid
            userId: user.id
          .exec (err, data) ->
            console.log err if err
            unless err or data
              newTrack = new theModel track
              newTrack.id = track.mbid
              newTrack.userId = user.id
              newTrack.user_name = user.services.lastfm.userId
              newTrack.created_at = new Date(parseInt(track.date.uts) * 1000)
              newTrack.artist_name = track.artist['#text']
              newTrack.album_name = track.album['#text']
              newTrack.save (err) ->
                console.log err

  getRecentTracks: (user, callback) ->
    client = @createClient(user)
    client.request 'user.getRecentTracks',
      user: user.services.lastfm.userId
      limit: 100
      format: 'json'
    .on 'success', (json) ->
      callback(null, json)
    .on 'error', (err) ->
      callback(err)

  createClient: (user) ->
    if user and user.services and user.services.lastfm
      new lastfmnode(config)

module.exports = new LastFmService()
