REPO = process.env.REPO
module.exports = (robot) ->
  child_process = require 'child_process'

  github = require('githubot')(robot, errorHandler: (response) ->
    msg.send "```#{response.error}```🤔"
    )

  merge = (msg, target) ->
    github.get "/repos/tootsuite/mastodon/branches/master", (master) ->
      github.branches(REPO).merge master.commit.sha,
        into: target, () ->
          msg.send "マージ成功🎉"

  current_branch = () -> robot.brain.get "branch"

  robot.respond /(masterマージ|merge master)/i, (msg) ->
    target = current_branch()
    if !target
      msg.send "checkout target branch before merging"
    else
      merge(msg, target)

  robot.respond /checkout (.+)/i, (msg) ->
    branch = msg.match[1]
    if branch.length == 0
      msg.send "enter branch name"
      return
    robot.brain.set "branch", branch
    msg.send branch

  robot.respond /branch/i, (msg) ->
    github.branches REPO, (branches) ->
      msg.send branches.map((b) -> "* #{b.name}").join "\n"
      msg.send "current_branch: #{current_branch()}"

  robot.respond /(デプロイ|でっぷろーい)/i, (msg) ->
    child_process.exec "scripts/shell/deploy.sh #{current_branch()} hubot", (error, stdout, stderr) ->
      if !error
        msg.send "🎉\n" + stdout
      else
        msg.send "```#{stderr}```🤔"

  robot.respond /masterにドン/i, (msg) ->
    msg.send "🐘＜アップデートなう"
    child_process.exec "scripts/shell/chase_master.sh hubot", (error, stdout, stderr) ->
      if !error
        msg.send "アップデート完了🎉\n" + stdout
      else
        msg.send "```#{stderr}```🤔"

  robot.respond /リフレッシュ/i, (msg) ->
    msg.send "🐘＜リフレッシュなう"
    child_process.exec "scripts/shell/refresh_mastodon.sh", (error, stdout, stderr) ->
      if !error
        msg.send "🌴リフレッシュ完了🌴"

      else
        msg.send "```#{stderr}```\n🤔リフレッシュ失敗"

  robot.respond /再起動/i, (msg) ->
    msg.send "🐘＜`sudo systemctl restart mastodon-*.service`"
    child_process.exec "sudo systemctl restart mastodon-*.service", (error, stdout, stdercocr) ->
      if !error
        msg.send "```#{stdout}```OK🎉"
      else
        msg.send "```#{stderr}```🤔"

  robot.respond /diff/i, (msg) ->
    msg.send "🐘＜`git diff upstream/master --name-only`"
    child_process.exec "scripts/shell/show_diff.sh", (error, stdout, stderr) ->
      if error
        msg.send error
      else if stdout.trim().length > 0
        msg.send stdout
      else
        msg.send "no diffs"
