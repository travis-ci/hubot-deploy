# Description
#   Enable deployments from chat that correctly attribute you as the creator - https://github.com/atmos/hubot-deploy
#
# Commands:
#   hubot deploy-token:set - Set your user's deployment token. You'll get a private message with a URL to set the token.
#   hubot deploy-token:reset - Resets your user's deployment token. Requires repo_deployment scope.
#
supported_tasks = [ "#{DeployPrefix}-token" ]

uuid = require 'node-uuid'
HerokuUrl = process.env.HEROKU_URL

Path           = require("path")
Patterns       = require(Path.join(__dirname, "..", "patterns"))
Deployment     = require(Path.join(__dirname, "..", "deployment")).Deployment
DeployPrefix   = Patterns.DeployPrefix
DeployPattern  = Patterns.DeployPattern
DeploysPattern = Patterns.DeploysPattern

TokenVerifier  = require(Path.join(__dirname, "..", "token_verifier")).TokenVerifier
###########################################################################
module.exports = (robot) ->
  robot.respond ///#{DeployPrefix}-token:set///i, (msg) ->
    user = robot.brain.userForId msg.envelope.user.id
    user.verifyToken = uuid.v4()
    robot.messageRoom msg.envelope.user.id, "Enter your token here: " + HerokuUrl + "/hubot-deploy/token?verify_token=" + user.verifyToken + "&user_id=" + msg.envelope.user.id

  robot.respond ///#{DeployPrefix}-token:reset///i, (msg) ->
    user = robot.brain.userForId msg.envelope.user.id
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
      verifier = new TokenVerifier(req.param 'token')
      verifier.valid (result) ->
        if result
          robot.messageRoom userId, "Your token is valid. I stored it for future use."
          user.githubDeployToken = verifier.token
        else
          robot.messageRoom userId, "Your token is invalid, verify that it has 'repo_deployment' scope."
