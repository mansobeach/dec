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

- `git config --global credential.helper store`

git config --global --unset core.askpass
git config --global --set core.askpass

git config --global credential.helper store
git config --show-origin --get credential.helper
cat /Users/borja/.gitconfig


### Create a new repository

`git init`
`git branch -m develop`

# do some git pull (twice to reset?)


### Undo a file
`git restore <file>`

`git restore -s SHA1 -- <filename>`

`git restore -s e575258ec397b7c2e66f14c0660fc45f57a57d03 -- NS1_TEST_TM__GPS____20220706T000000_20220709T000000_0001.xml`

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

git checkout master -- filename


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

git pull --rebase --autostash

git fetch
git checkout origin/develop <file_path>
git checkout origin/develop src/eboa/logging.py
git pull origin develop

Steps Branching
===============
git support_dhus_gnss
git checkout support_dhus_gnss

git checkout -b support_dhus_gnss master


### Git tagging & labeling
### https://git-scm.com/book/en/v2/Git-Basics-Tagging

Show tags with messages:
`git tag -n9`

Create tags with messages:
`git tag NAOS-TDS-GS-TEC-IVV-0600-TP-GS-VAL-0020-v1.1 -m "Version 1.1 of the TDS for TP-GS-VAL-0020 (NAOS-GS-TEC-IVV-0600)"`

Diff between tags
`git diff NAOS-TDS-GS-TEC-IVV-0600-TP-GS-VAL-0020-v1.0 NAOS-TDS-GS-TEC-IVV-0600-TP-GS-VAL-0020-v1.1  --stat`



