mongoose = require 'mongoose'
extend   = require 'mongoose-schema-extend'

EventSchema = mongoose.Schema
  id: String
  created_at: Date
  userId: mongoose.Schema.Types.ObjectId
,
  collection: 'events'
  discriminatorKey: '_type'

Event = mongoose.model 'Event', EventSchema, 'events'

require("fs").readdirSync(__dirname).forEach (file) ->
  file = file.replace('.coffee', '')
  unless file == 'event'
    modelClass = require(__dirname + '/' + file)(EventSchema)
    name = modelClass.modelName

    Event[name] = modelClass

Event.getEventType = (name) ->
  Event[name] if Event[name]

Event.prototype.toJSON = () ->
  console.log 'here in event'

module.exports = Event
