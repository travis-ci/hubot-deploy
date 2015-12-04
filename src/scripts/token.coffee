# Description
#   Enable deployments from chat that correctly attribute you as the creator - https://github.com/atmos/hubot-deploy
#
# Commands:
#   hubot deploy-token:set:github - Set your user's deployment token. You'll get a private message with a URL to set the token.
#   hubot deploy-token:reset:github - Resets your user's GitHub deployment token.
#   hubot deploy-token:verify:github - Verifies that your GitHub deployment token is valid.
#
supported_tasks = [ "#{DeployPrefix}-token" ]

uuid = require 'node-uuid'
HerokuUrl = process.env.HEROKU_URL

Path           = require("path")
Patterns       = require(Path.join(__dirname, "..", "models", "patterns"))
Deployment     = require(Path.join(__dirname, "..", "models", "deployment")).Deployment
DeployPrefix   = Patterns.DeployPrefix
DeployPattern  = Patterns.DeployPattern
DeploysPattern = Patterns.DeploysPattern

Verifiers = require(Path.join(__dirname, "..", "models", "verifiers"))

TokenForBrain    = Verifiers.VaultKey
ApiTokenVerifier = Verifiers.ApiTokenVerifier
###########################################################################
module.exports = (robot) ->
  robot.respond ///#{DeployPrefix}-token:set///i, (msg) ->
    user = robot.brain.userForId msg.envelope.user.id
    user.verifyToken = uuid.v4()
    robot.logger.info "user: #{user}\nid: #{user.id}\nroom: #{msg.envelope.user.id}"
    robot.send {room: msg.envelope.user.name}, "Enter your token here: " + HerokuUrl + "/hubot-deploy/token?verify_token=" + user.verifyToken + "&user_id=" + msg.envelope.user.id

  robot.respond ///#{DeployPrefix}-token:reset:github$///i, (msg) ->
    user = robot.brain.userForId msg.envelope.user.id
    robot.vault.forUser(user).unset(TokenForBrain)
    # Versions of hubot-deploy < 0.9.0 stored things unencrypted, encrypt them.
    delete(user.githubDeployToken)
    msg.reply "I nuked your deployment token. I'll use my default token until you configure another."

  robot.router.get "/hubot-deploy/token", (req, res) ->
    res.send "<!DOCTYPE html><html><body><p>Create a token <a href=\"https://github.com/settings/applications#personal-access-tokens\">here</a> with the repo_deployment scope and enter it below.</p><form action=\"/hubot-deploy/token\" method=\"POST\"><input type=\"text\" id=\"token\" name=\"token\"><input type=\"hidden\" name=\"verify_token\" id=\"verify_token\" value=\"" + req.param('verify_token') + "\"><input type=\"hidden\" name=\"user_id\" id=\"user_id\" value=\"" + req.param('user_id') + "\"><button type=\"submit\">save</button></form></body></html>"

  robot.router.post "/hubot-deploy/token", (req, res) ->
    userId = req.param 'user_id'
    user = robot.brain.userForId userId
    res.end ""
    if user.verifyToken == req.param 'verify_token'
      user.verifyToken = ""
      # Versions of hubot-deploy < 0.9.0 stored things unencrypted, encrypt them.
      delete(user.githubDeployToken)

      verifier = new ApiTokenVerifier(req.param 'token')
      verifier.valid (result) ->
        if result
          robot.vault.forUser(user).set(TokenForBrain, verifier.token)
          robot.send {room: user.name}, "Your token is valid. I stored it for future use."
        else
          robot.send {room: user.name}, "Your token is invalid, verify that it has 'repo' scope."
    msg.reply "I nuked your GitHub token. I'll try to use my default token until you configure another."

  robot.respond ///#{DeployPrefix}-token:verify:github$///i, (msg) ->
    user = robot.brain.userForId msg.envelope.user.id
    # Versions of hubot-deploy < 0.9.0 stored things unencrypted, encrypt them.
    delete(user.githubDeployToken)
    token = robot.vault.forUser(user).get(TokenForBrain)
    verifier = new ApiTokenVerifier(token)
    verifier.valid (result) ->
      if result
        msg.send "Your GitHub token is valid on #{verifier.config.hostname}."
      else
        msg.send "Your GitHub token is invalid, verify that it has 'repo' scope."
