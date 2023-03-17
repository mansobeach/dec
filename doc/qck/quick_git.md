[//]: # (===================================================)
[//]: # ($Author: bolf$)
[//]: # ($Date$)
[//]: # ($Committer: bolf$)
[//]: # ($Hash: ec8e3ee$)
[//]: # (===================================================)

### Git Configuration


## Show Configuration

- `git config --list`


Configuration commands to log the user working in the repository

- `git config --global user.name "Your Name"`

- `git config --global user.email you@example.com`

- `git config --global alias.lgb "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s
%Cgreen(%cr) %C(bold blue)<%an>%Creset%n' --abbrev-commit --date=relative --branches"`

- `git config --global core.editor vim`

- `git config --global core.excludesfile ~/.gitignore`

`git clone https://username:password@remote`


### Management of credentials

git config --global --unset core.askpass
git config --global --set core.askpass

git config --global credential.helper store
git config --show-origin --get credential.helper
cat /Users/borja/.gitconfig

# do some git pull (twice to reset?)


### Undo a commit

`git revert <commit_id>`


### Retrieve <master> branch from repository

`git pull origin master`

### List remote repositories

`git remote -v`

### List all branches

- `git branch -a`

- `git lgb`

Remove a local branch
- `git branch --delete support_dhus_gnss`

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


### Retrieve a file from the repository

git checkout master -- <filename>


Delete a file
=============

git rm <file>

Delete submodule <cache>
========================

git rm --cached code/ws23rb


### Git differences with respect different commits

git diff <commit_id> /path/filename



### Management

status of the HEAD pointer
==========================

git cat-file -p HEAD

git cat-file -p HEAD^{tree}

git log -3



Configuration
=============
git config pull.rebase true
git config branch.autosetuprebase always

Resolve conflicts from remote repository
========================================
git pull --rebase

git fetch
git checkout origin/develop <file_path>
git checkout origin/develop src/eboa/logging.py
git pull origin develop

Steps Branching
===============
git support_dhus_gnss
git checkout support_dhus_gnss

git checkout -b support_dhus_gnss master




