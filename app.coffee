express = require 'express'
everyauth = require 'everyauth'
bcrypt = require 'bcrypt'
mongojs = require 'mongojs'
mongoose = require 'mongoose'
express = require 'express'
connectRedis = require('connect-redis')(express)
partials = require 'express-partials'
less = require 'less-middleware'
url = require 'url'
path = require 'path'
jade = require 'jade'
moment = require 'moment'
coffeescript = require 'connect-coffee-script'
http = require 'http'
_ = require 'underscore'
app = express()

mongoose.connect process.env.MONGOHQ_URL || process.env.MONGOLAB_URI || process.env.MONGODB_URL || 'mongodb://localhost/activitystream'
User = require('./src/models/user')
Event = require('./src/models/event')

findUserById = (userId, callback) ->
  User.findOne
    _id: userId
  .exec (err, data) ->
    callback(err, data)

everyauth.everymodule.findUserById findUserById

# Load all the various services, and connect them to
# everyauth
services = require('./src/services/base').loadServices(everyauth)

caller = () ->
  User.find().exec (err, data) ->
    data.forEach (user) ->
      if user and user.services
        Object.keys(user.services).forEach (service) ->
          services[service].scrapeItems(user) if services[service].scrapeItems

setupCaller = () ->
  caller()
  setInterval ->
    caller()
  , 60 * 60 * 1000 # Every hour

pinger = () ->
  service_url = (process.env.SERVICE_URL || 'http://localhost:' + process.env.PORT || 5000) + "/ping"
  console.log "pinging", service_url
  http.get(service_url, (res) ->
  ).on 'error', (err) ->
    console.log err

setupPinger = () ->
  pinger()
  setInterval ->
    pinger()
  , 60 * 15 * 1000 # 15 min

allowCrossDomain = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS'
  res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With'

  if 'OPTIONS' == req.method
    res.send 200
  else
    next()

app.configure () ->
  app.use allowCrossDomain
  bootstrapPath = path.join(__dirname, 'node_modules', 'bootstrap')
  app.set('view engine', 'jade')
  app.use partials()
  app.use express.bodyParser()
  app.use express.favicon()
  app.use express.cookieParser()
  redisUrl = url.parse(process.env.REDISTOGO_URL || process.env.BOXEN_REDIS_URL || "redis://localhost:6379")
  redisAuth = if redisUrl.auth then redisUrl.auth.split(':') else ['', '']
  app.use express.session
    store:  new connectRedis
      host: redisUrl.hostname
      port: redisUrl.port
      db: redisAuth[0]
      pass: redisAuth[1]
    secret: 'lksjdflkjswoiojsmxnvsdlkweiorjslkxkvnslkdfliworislkxlkjxlkjvmsdljweijxlkfxcklvdmfglkdsgiowpalksfmnxcvmsdligjdlkgjcxnxcvmnsflkjsdfiljseflknxvmnsdlkfj'
  app.use everyauth.middleware(app)
  app.use '/img', express['static'](path.join(bootstrapPath, 'img'))
  app.use less
    src: path.join(__dirname, 'assets', 'less')
    paths: [path.join(bootstrapPath, 'less')]
    dest : path.join(__dirname, 'public', 'stylesheets')
    prefix: '/stylesheets'
  app.use coffeescript
    src: path.join(__dirname, 'assets', 'coffeescript')
    dest: path.join(__dirname, 'public', 'javascripts')
    prefix: '/javascripts'
    bare: true
  app.use express.static(__dirname + "/public")

  partials.register '.jade', (str, options) ->
    tmpl = null
    jade.render(str, options, (err, value) ->
      throw err if err?
      tmpl = value
    )
    tmpl

app.get '/', (req, res) =>
  res.render 'home',
    services: services
    user: req.user

app.param 'login', (req, res, next, id) ->
  User.findUser id, (err, user) ->
    if err
      next(err)
    else if user
      req.user = user
      next()
    else
      next(new Error('failed to load user'))

app.param 'page', (req, res, next, id) ->
  req.page = if id and parseInt(id) then id else 1
  next()

app.param 'service', (req, res, next, id) ->
  foundService = _(services).any (service) ->
    service.name == id
  if foundService
    req.service = id
    next()
  else
    next(new Error('service does not exist'))

app.get '/disconnect/:service', (req, res) ->
  update = {}
  update['services.' + req.service] = ''
  req.user.update {$unset: update}, {w: 1}, (err, ret) ->
    if err
      res.send err
    else
      res.redirect('/')

app.get '/ping', (req, res) ->
  console.log "PONG"
  res.send 'OK'

app.get '/embed', (req, res) ->
  res.render 'embed-base'

app.get '/stream/:login/:page?', (req, res) ->
  req.accepts('html, json')

  len = req.query.limit || 50
  skip = ((req.page or 1) - 1) * len

  Event.count
    userId: req.user.id
  , (err, count) ->
    unless err
      Event.find
        userId: req.user.id
      .limit(len)
      .skip(skip)
      .sort('-created_at')
      .exec (err, data) ->
        if req.is('json') or (req.query.format and req.query.format == 'json')
          res.json
            events: data
            page: req.page or 1
            total_items: count
            total_pages: (if len > 0 then Math.ceil(count / len) else 1)
        else
          res.render 'stream',
            events: data
            user: req.user
            formatTime: (theDate) ->
              moment(theDate).format('h:mm a')

port = process.env.PORT || 5000
app.listen port
console.log "Started on port #{port}"

setupCaller()
setupPinger()
