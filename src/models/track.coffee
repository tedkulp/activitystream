mongoose = require 'mongoose'
moment = require 'moment'

module.exports = (ParentSchema) ->

  TrackSchema = ParentSchema.extend
    name: String
    artist_name: String
    album_name: String
    user_name: String
    url: String

  Track = mongoose.model 'Track', TrackSchema, 'events'

  Track.prototype.displayHtml = ->
    output = []
    output.push "<a class='event-user-name'>#{@.user_name}</a>"
    output.push "listened to"
    output.push "<a target='blank' class='event-link' href='#{@url}'>#{@artist_name} - #{@name}</a>"
    output.push "<span class='event-date'>#{moment(@created_at).format('h:mm a')}</span>"
    output.join(' ')

  Track.prototype.origToJSON = Track.prototype.toJSON
  Track.prototype.toJSON = () ->
    json = @origToJSON.call(@)
    json.html = @displayHtml()
    json

  Track
