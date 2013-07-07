mongoose = require 'mongoose'
twitter = require 'twitter-text'
moment = require 'moment'

module.exports = (ParentSchema) ->

  TweetSchema = ParentSchema.extend
    text: String
    retweet_count: Number
    user_screen_name: String
    retweet:
      type: Boolean
      default: false
    reply:
      type: Boolean
      default: false
    action:
      type: String
      default: "tweeted"
    pointer_status_id: String
    original_screen_name: String
    original_user_id: String
    entities_urls: mongoose.Schema.Types.Mixed
    entities_media: mongoose.Schema.Types.Mixed

  Tweet = mongoose.model 'Tweet', TweetSchema, 'events'

  Tweet.prototype.linkedText = ->
    entities = @urlEntities()

    if entities.length > 0
      " &quot;" + twitter.autoLink(@get('text'),
        urlEntities: entities
        targetBlank: true
      ) + "&quot;"
    else
      " &quot;" + twitter.autoLink(twitter.htmlEscape(@get('text')),
        targetBlank: true
      ) + "&quot;"

  Tweet.prototype.urlEntities = ->
    ret = []
    ret = ret.concat @entities_urls if @entities_urls
    ret = ret.concat @entities_media if @entities_media
    ret

  Tweet.prototype.originalUrl = ->
    "http://twitter.com/#{@get('user_screen_name')}/status/#{@get('id')}"

  Tweet.prototype.displayHtml = ->
    output = []
    output.push "<a class='event-user-name'>#{@.user_screen_name}</a>"
    if @retweet
      output.push "<a class='event-link' href='#{@originalUrl()}'>#{@action}</a>"
      output.push "<a class='event-link' href='http://twitter.com/#{@original_screen_name}'>#{@original_screen_name}</a>"
    else
      output.push "<a href='#{@originalUrl()}' class='event link'>#{@action}</a>"
    output.push @linkedText()
    output.push "<span class='event-date'>#{moment(@created_at).format('h:mm a')}</span>"
    output.join(' ')

  Tweet.prototype.origToJSON = Tweet.prototype.toJSON
  Tweet.prototype.toJSON = () ->
    json = @origToJSON.call(@)
    json.html = @displayHtml()
    json

  Tweet.createObjectFromData = (tweet, user) ->
    tweetObj = new Tweet tweet
    tweetObj.id = tweet.id_str
    tweetObj.user_screen_name = tweet.user.screen_name
    tweetObj.userId = user.id
    tweetObj.entities_urls = tweet.entities.urls if tweet.entities.urls
    tweetObj.entities_media = tweet.entities.media if tweet.entities.media

    # Retweet?
    if tweet.retweeted_status?
      tweetObj.action = 'retweeted'
      tweetObj.text = tweet.retweeted_status.text
      tweetObj.pointer_status_id = tweet.retweeted_status.id_str
      tweetObj.original_screen_name = tweet.retweeted_status.user.screen_name
      tweetObj.original_user_id = tweet.retweeted_status.user.id_str
      tweetObj.retweet_count = tweet.retweeted_status.retweet_count
      tweetObj.retweet = true

      tweetObj.entities_urls = tweet.retweeted_status.entities.urls if tweet.retweeted_status.entities.urls
      tweetObj.entities_media = tweet.retweeted_status.entities.media if tweet.retweeted_status.entities.media

    # Reply?
    if tweet.in_reply_to_status_id_str != null
      tweetObj.action = 'replied'
      tweetObj.pointer_status_id = tweet.in_reply_to_status_id_str
      tweetObj.original_screen_name = tweet.in_reply_to_screen_name
      tweetObj.original_user_id = tweet.in_reply_to_user_id_str
      tweetObj.reply = true

    tweetObj

  Tweet
