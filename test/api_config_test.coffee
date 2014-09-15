Path = require('path')

ApiConfig = require(Path.join(__dirname, "..", "src", "api_config"))

describe "ApiConfig", () ->
  describe "defaults", () ->
    user =
      githubDeployToken: "xxx"
    apiConfig = new ApiConfig.ApiConfig(user, null)

    it "fetches the GitHub API token provided", () ->
      assert.equal "xxx", apiConfig.token
    it "defaults to api.github.com", () ->
      assert.equal "api.github.com", apiConfig.hostname
    it "handles no path suffix requests", () ->
      assert.equal "/", apiConfig.path("")
    it "handles path suffixes", () ->
      assert.equal "/repos/atmos/heaven/deployments", apiConfig.path("repos/atmos/heaven/deployments")

  describe "enterprise aware chat user tokens", () ->
    user =
      githubDeployTokens =
        'api.github.com': "xxx"
        'enterprise.mycompany.com': 'zzz'
    config =
      application =
        github_api:   "https://enterprise.mycompany.com/api/v3/"
        github_token: "yyy"
    apiConfig = new ApiConfig.ApiConfig(user, application)

    it "fetches the custom GitHub API token", () ->
      assert.equal "zzz", apiConfig.token
    it "uses the application api_url field for hostname", () ->
      assert.equal "enterprise.mycompany.com", apiConfig.hostname
    it "handles no path suffix requests", () ->
      assert.equal "/api/v3/", apiConfig.path("")
    it "handles path suffixes", () ->
      assert.equal "/api/v3/repos/atmos/heaven/deployments", apiConfig.path("repos/atmos/heaven/deployments")

  describe "enterprise aware urls and tokens", () ->
    user =
      githubDeployToken: "xxx"
    config =
      application =
        github_api:   "https://enterprise.mycompany.com/api/v3/"
        github_token: "yyy"
    apiConfig = new ApiConfig.ApiConfig(user, application)

    it "fetches the custom GitHub API token from the application", () ->
      assert.equal "yyy", apiConfig.token
    it "uses the application api_url field for hostname", () ->
      assert.equal "enterprise.mycompany.com", apiConfig.hostname
    it "handles no path suffix requests", () ->
      assert.equal "/api/v3/", apiConfig.path("")
    it "handles path suffixes", () ->
      assert.equal "/api/v3/repos/atmos/heaven/deployments", apiConfig.path("repos/atmos/heaven/deployments")

