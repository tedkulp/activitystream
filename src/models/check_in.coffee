mongoose = require 'mongoose'
moment = require 'moment'

module.exports = (ParentSchema) ->

  CheckInSchema = ParentSchema.extend
    shout: String
    user_name: String
    foursquare_user_id: String
    full_name: String
    venue_name: String
    venue_url: String

  CheckIn = mongoose.model 'CheckIn', CheckInSchema, 'events'

  CheckIn.prototype.displayHtml = ->
    output = []
    output.push "<a class='event-user-name'>#{@full_name}</a>"
    output.push "<a target='blank' href='https://foursquare.com/#{@foursquare_user_id}/checkin/#{@id}'>checked in</a> at"
    output.push "<a target='blank' href='#{@venue_url}'>#{@venue_name}</a>"
    output.push "and shouted &quot;#{@shout}&quot;" if @shout and @shout.length > 0
    output.push "<span class='event-date'>#{moment(@created_at).format('h:mm a')}</span>"
    output.join(' ')

  CheckIn.prototype.origToJSON = CheckIn.prototype.toJSON
  CheckIn.prototype.toJSON = () ->
    json = @origToJSON.call(@)
    json.html = @displayHtml()
    json

  CheckIn
