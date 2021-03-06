VCR  = require "ys-vcr"
Path = require "path"

srcDir = Path.join(__dirname, "..", "..", "..", "src")

Version    = require(Path.join(srcDir, "version")).Version
Deployment = require(Path.join(srcDir, "models", "deployment")).Deployment

describe "Deployment#rawPost", () ->
  beforeEach () ->
    VCR.playback()
  afterEach () ->
    VCR.stop()

  it "does not create a deployment due to bad authentication", (done) ->
    VCR.play '/repos-atmos-hubot-deploy-deployment-production-create-bad-auth'
    deployment = new Deployment("hubot-deploy", "master", "deploy", "production", "", "")
    deployment.rawPost (err, status, body, headers) ->
      unless err
        throw new Error("Should've thrown bad auth")

      assert.equal "Bad credentials", err.message
      assert.equal 401, err.statusCode
      done()

  it "does not create a deployment due to missing required commit statuses", (done) ->
    VCR.play '/repos-atmos-hubot-deploy-deployment-production-create-required-status-missing'
    deployment = new Deployment("hubot-deploy", "master", "deploy", "production", "", "")
    deployment.rawPost (err, status, body, headers) ->
      throw err if err
      assert.equal 409, status
      assert.equal "Conflict: Commit status checks failed for master", body.message
      done()

  it "does not create a deployment due to failing required commit statuses", (done) ->
    VCR.play '/repos-atmos-hubot-deploy-deployment-production-create-required-status-failing'
    deployment = new Deployment("hubot-deploy", "master", "deploy", "production", "", "")
    deployment.rawPost (err, status, body, headers) ->
      throw err if err
      assert.equal 409, status
      assert.equal "Conflict: Commit status checks failed for master", body.message
      assert.equal "continuous-integration/travis-ci/push", body.errors[0].contexts[0].context
      assert.equal "code-climate", body.errors[0].contexts[1].context
      done()

  it "sometimes can't auto-merge  when the requested ref is behind the default branch", (done) ->
    VCR.play '/repos-atmos-hubot-deploy-deployment-production-create-auto-merged-failed'
    deployment = new Deployment("hubot-deploy", "topic", "deploy", "production", "", "")
    deployment.rawPost (err, status, body, headers) ->
      throw err if err
      assert.equal 409, status
      assert.equal "Conflict merging master into topic.", body.message
      done()

  it "successfully auto-merges when the requested ref is behind the default branch", (done) ->
    VCR.play '/repos-atmos-hubot-deploy-deployment-production-create-auto-merged'
    deployment = new Deployment("hubot-deploy", "topic", "deploy", "production", "", "")
    deployment.rawPost (err, status, body, headers) ->
      throw err if err
      assert.equal 202, status
      assert.equal "Auto-merged master into topic on deployment.", body.message
      done()

  it "successfully created deployment", (done) ->
    VCR.play '/repos-atmos-hubot-deploy-deployment-production-create-success'
    deployment = new Deployment("hubot-deploy", "master", "deploy", "production", "", "")
    deployment.rawPost (err, status, body, headers) ->
      throw err if err
      assert.equal 201, status
      assert.equal "deploy", body.deployment.task
      assert.equal "production", body.deployment.environment
      done()
