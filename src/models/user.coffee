mongoose = require 'mongoose'

Schema = mongoose.Schema
UserSchema = new Schema
  email: String
  hash: String
  salt: String
  services:
    type: Schema.Types.Mixed
    default: {}
,
  strict: false

modelObject = mongoose.model 'User', UserSchema

modelObject.findUser = (login, callback) ->
  @findOne
    login: login
  .exec (err, data) ->
    callback(err, data)

modelObject.createUser = (newUserAttrs, callback) ->
  newUser = new modelObject(newUserAttrs)
  newUser.save (err, data) ->
    callback(err, data)


module.exports = modelObject
