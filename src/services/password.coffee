ServiceBase = require './base'
User = require '../models/user'

bcrypt = require 'bcrypt'

class PasswordService extends ServiceBase
  setup: (everyauth) ->
    `var that = this`
    everyauth.password
      .loginWith('login')
      .getLoginPath('/login')
      .postLoginPath('/login')
      .loginView('login.jade')
      # .loginLocals((req, res, done) ->
      #   setTimeout () ->
      #     done null,
      #       title: 'Async login'
      # , 200)
      .authenticate (login, password) ->
        errors = []
        errors.push('Missing login') unless login
        errors.push('Missing password') unless password

        return errors if errors.length

        promise = @Promise()

        # findUser passes an error or user to a callback after finding the
        # user by login
        User.findUser login, (err, user) ->
          if err
            errors.push(err.message || err)
            return promise.fulfill(errors)

          unless user
            errors.push('Login failed')
            return promise.fulfill(errors)

          bcrypt.compare password, user.hash, (err, didSucceed) ->
            return promise.fail(err) if err

            return promise.fulfill(user) if didSucceed

            errors.push('Login failed')
            return promise.fulfill(errors)

        promise
      .getRegisterPath('/register')
      .postRegisterPath('/register')
      .registerView('register.jade')
      # .registerLocals((req, res, done) ->
      #   setTimeout () ->
      #     done null,
      #       title: 'Async register'
      # , 200)
      .extractExtraRegistrationParams (req) ->
        email: req.body.email
      .validateRegistration (newUserAttrs) ->
        errors = []
        errors.push('No login entered') unless newUserAttrs.login
        errors.push('No password entered') unless newUserAttrs.password
        errors
      .registerUser (newUserAttrs) ->
        promise = @Promise()

        password = newUserAttrs.password
        delete newUserAttrs.password; # Don't store password

        newUserAttrs.salt = bcrypt.genSaltSync(10)
        newUserAttrs.hash = bcrypt.hashSync(password, newUserAttrs.salt)

        # Create a new user in your data store
        User.createUser newUserAttrs, (err, createdUser) ->
          return promise.fail(err) if err
          return promise.fulfill(createdUser)

        promise
      .loginSuccessRedirect('/')
      .registerSuccessRedirect('/')

module.exports = new PasswordService()
