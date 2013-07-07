# Activitystream

### Capturing your online persona, all in one place

Activity stream is a tool for capturing your exploits from various social
networks, and displaying them in one place. It uses node.js, MongoDB and Redis, and
runs conveniently on Heroku.

Deploying to Heroku
-------------------

  * Clone the repository

```bash
git clone http://github.com/tedkulp/activitystream.git
```

  * Create & configure for Heroku

```bash
gem install heroku
heroku create example-errbit --stack cedar
heroku addons:add mongohq:sandbox                  # mongolab:sandbox works too
heroku addons:add redistogo:nano
heroku config:add SERVICE_URL="http://$(heroku domains | grep "herokuapp.com")"
```

  * Setup Flickr
    * *Note*: Flickr is optional. If the FLICKR_KEY isn't set, Flickr will not
      be a active service.
    * Visit [http://www.flickr.com/services/apps/create/](), get an API key and
      setup a new application for Activitystream.
    * Add the keys for your new application to the Heroku config

```bash
heroku config:add FLICKR_KEY=1234567890abcdef
heroku config:add FLICKR_SECRET=1234567890abcdef
```

  * Setup Foursquare
    * *Note*: Foursquare is optional. If the FOURSQUARE_ID isn't set,
      Foursquare will not be a active service.
    * Visit [https://foursquare.com/developers/apps](), create a new
      application for Activitystream.
    * Add the keys for your new application to the Heroku config

```bash
heroku config:add FOURSQUARE_ID=1234567890abcdef
heroku config:add FOURSQUARE_SECRET=1234567890abcdef
```

  * Setup Github
    * *Note*: Github is optional. If the GITHUB_ID isn't set,
      Github will not be a active service.
    * Visit [https://github.com/settings/applications](), create a new
      application for Activitystream.
    * Add the keys for your new application to the Heroku config

```bash
heroku config:add GITHUB_ID=1234567890abcdef
heroku config:add GITHUB_SECRET=1234567890abcdef
```

  * Setup Last.FM
    * *Note*: Last.FM is optional. If the LASTFM_KEY isn't set,
      Last.FM will not be a active service.
    * Visit [http://www.last.fm/api/accounts](), create a new
      application for Activitystream.
    * Add the keys for your new application to the Heroku config

```bash
heroku config:add LASTFM_KEY=1234567890abcdef
heroku config:add LASTFM_SECRET=1234567890abcdef
```

  * Setup Twitter
    * *Note*: Twitter is optional. If the TWITTER_KEY isn't set,
      Twitter will not be a active service.
    * Visit [https://dev.twitter.com/apps](), create a new
      application for Activitystream.
    * Add the keys for your new application to the Heroku config

```bash
heroku config:add TWITTER_KEY=1234567890abcdef
heroku config:add TWITTER_SECRET=1234567890abcdef
```

  * Push to heroku

```bash
git push heroku master
```
