Url      = require "url"
Path     = require "path"
###########################################################################
class ApiConfig
  constructor: (@chatUser, @application) ->
    @token = @chatUser.githubDeployToken

    @parsedApiUrl = Url.parse(@apiUri())
    @hostname     = @parsedApiUrl.host

  apiUri: ->
    (@application? and @application['github_api']) or
      process.env.HUBOT_GITHUB_API or
      'https://api.github.com'

  apiToken: ->
    (@application? and @application['github_token']) or @chatUserGitHubToken

  chatUserGitHubToken: ->
    tokenConfig = @chatUser.githubDeployTokens
    if tokenConfig? and tokenConfig[@hostname]?
      tokenConfig[@hostname]
    else
      @chatUser.githubDeployToken

  filterPaths: ->
    newArr = @pathParts().filter (word) -> word isnt ""

  pathParts: ->
    @parsedApiUrl.path.split("/")

  path: (suffix) ->
    if suffix?.length > 0
      parts = @filterPaths()
      parts.push(suffix)
      "/#{parts.join('/')}"
    else
      @parsedApiUrl.path

exports.ApiConfig = ApiConfig
