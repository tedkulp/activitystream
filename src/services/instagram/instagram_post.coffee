mongoose = require 'mongoose'
moment = require 'moment'

module.exports = (ParentSchema) ->

  InstagramPostSchema = ParentSchema.extend
    id: String
    type: String
    username: String
    location:
      id: Number
      name: String
    caption: String
    link: String
    filter: String
    images: mongoose.Schema.Types.Mixed
    videos: mongoose.Schema.Types.Mixed

  InstagramPost = mongoose.model 'InstagramPost', InstagramPostSchema, 'events'

  InstagramPost.createObjectFromData = (data, user) ->
    post = new InstagramPost data
    post.id = data.id
    post.type = data.type
    post.link = data.link
    post.filter = data.filter
    post.userId = user.id
    post.username = data.user.username
    post.created_at = new Date(parseInt(data.created_time) * 1000)

    if data.location
      if data.location.id
        post.location.id = data.location.id
      if data.location.name
        post.location.name = data.location.name

    if data.caption and data.caption.text
      post.caption = data.caption.text

    if data.images
      post.images = data.images

    if data.videos
      post.videos = data.videos

    post

  InstagramPost.prototype.displayHtml = ->
    output = []
    output.push "<a class='event-user-name'>#{@username}</a>"
    if @type == 'video'
      output.push "<a target='blank' href='#{@link}'>posted a #{@type}</a>"
    else
      output.push "<a target='blank' href='#{@link}'>posted an #{@type}</a>"
    output.push "at #{@location.name}" if @location.name and @location.name.length > 0
    output.push "with a caption of \"#{@caption}\"" if @caption and @caption.length > 0
    output.push "<span class='event-date'>#{moment(@created_at).format('h:mm a')}</span>"
    output.join(' ')

  InstagramPost.prototype.origToJSON = InstagramPost.prototype.toJSON
  InstagramPost.prototype.toJSON = () ->
    json = @origToJSON.call(@)
    json.html = @displayHtml()
    json

  InstagramPost
