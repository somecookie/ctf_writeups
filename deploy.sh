#!/bin/sh

echo "If a command fails then the deploy stops"
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

echo "Build the project."
hugo -t hello-friend # if using a theme, replace with `hugo -t <YOURTHEME>`

echo "Go To Public folder"
cd public

echo "Add changes to git."
git add .

echo "Commit changes."
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

echo "Push source and build repos."
git push origin master

