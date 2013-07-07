User = require '../models/user'

class ServiceBase
  tap: () ->
    fn = Array.prototype.shift.apply(arguments)
    fn.apply(this, arguments)
    return this

  setUserAttrsForService: (userId, serviceName, attrs, callback) ->
    attrsToSave = []
    attrsToSave['services.' + serviceName] = attrs
    User.findByIdAndUpdate userId, attrsToSave, {upsert: true}, (err, data) ->
      callback(err, data)

ServiceBase.loadServices = (everyauth) ->
  services = {}
  require("fs").readdirSync(__dirname).forEach (file) ->
    file = file.replace('.coffee', '')
    unless file == 'base'
      services[file] = require(__dirname + '/' + file).tap () ->
        @setup(everyauth)
  services

module.exports = ServiceBase
