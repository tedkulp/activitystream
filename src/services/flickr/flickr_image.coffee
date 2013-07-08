mongoose = require 'mongoose'
moment = require 'moment'

module.exports = (ParentSchema) ->

  FlickrImageSchema = ParentSchema.extend
    owner: String
    secret: String
    server: String
    farm: String
    title: String
    pathalias: String

  FlickrImage = mongoose.model 'FlickrImage', FlickrImageSchema, 'events'

  FlickrImage.prototype.displayHtml = ->
    output = []
    output.push "<a class='event-user-name'>#{@pathalias}</a>"
    output.push "posted"
    output.push "<a target='blank' href='http://flickr.com/photos/#{@pathalias}/#{@id}'>#{@title}</a>"
    output.push "<span class='event-date'>#{moment(@created_at).format('h:mm a')}</span>"
    output.join(' ')

  FlickrImage.prototype.origToJSON = FlickrImage.prototype.toJSON
  FlickrImage.prototype.toJSON = () ->
    json = @origToJSON.call(@)
    json.html = @displayHtml()
    json

  FlickrImage
