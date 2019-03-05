[//]: # (===================================================)
[//]: # ($Author: bolf$)
[//]: # ($Date$)
[//]: # ($Committer: bolf$)
[//]: # ($Hash: ec8e3ee$)
[//]: # (===================================================)

### Git Configuration

Configuration commands to log the user working in the repository

- `git config --global user.name "Your Name"`

- `git config --global user.email you@example.com`

- `git config --global alias.lgb "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s
%Cgreen(%cr) %C(bold blue)<%an>%Creset%n' --abbrev-commit --date=relative --branches"`

- `git config --global core.editor vim`

`git clone https://username:password@remote`

### Undo a commit

`git revert <commit_id>`


### Retrieve <master> branch from repository

`git pull origin master`

### List remote repositories

`git remote -v`

### List all branches

- `git branch -a`

- `git lgb`

---

### Remote repositories

`git remote set-url origin root@casale-redmine:/var/cache/git/dec.git`

`git remote add bitbucket https://borja_lopez_fernandez@bitbucket.org/borja_lopez_fernandez/dec.git`

### Recover last version of a file

`git checkout origin/master -- FTPClientCommands.rb`

### Force pull into local

`git fetch --all`

`git reset --hard origin/master`

---

### Smudge & Clean Operations

-	`git config filter.dater.smudge git_expand_attributes`

-	`git config filter.dater.clean 'perl -pe "s/\\\$Date$]\*\\\$/\\\$Date\\\$/"'`

---

git config receive.denyCurrentBranch ignore

git push origin master -f git push -u bitbucket --all # pushes up the repo and its refs for the first time git push -u bitbucket --tags # pushes up any tags

git config core.bare false

git cat-file -p 3b18e512dba79e4c8300dd08aeb37f8e728b8dad

Delete a file
=============

git rm <file>

Delete submodule <cache>
========================

git rm --cached code/ws23rb
