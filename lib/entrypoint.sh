#!/bin/bash
set -u

echo "::group::Internal logs"

cd $INPUT_CWD
echo "Running in $PWD."

echo "---------------------------------------------"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $DIR
python3 -m pip install setuptools
python3 -m pip install -r "$DIR/../requirements.txt"
RC=".gitchangelog.rc"
if ! [[ -f "$RC" ]]
then
    echo "Copying in $RC"
    cp $DIR/../$RC ./
else
    RC=""
fi
if [[ -n "$INPUT_VERSIONFILE" ]]
then
    INPUT_VERSIONFILE='.version'
fi
if [[ -n "$INPUT_CHANGELOGFILE" ]]
then
    INPUT_CHANGELOGFILE='CHANGELOG.md'
echo "---------------------------------------------"

# Set up .netrc file with GitHub credentials
git_setup() {
    cat <<-EOF >$HOME/.netrc
        machine github.com
        login $GITHUB_ACTOR
        password $GITHUB_TOKEN

        machine api.github.com
        login $GITHUB_ACTOR
        password $GITHUB_TOKEN
EOF
    chmod 600 $HOME/.netrc
    git config --global user.email "$INPUT_AUTHOR_EMAIL"
    git config --global user.name "$INPUT_AUTHOR_NAME"
}

add() {
    if $INPUT_FORCE; then f=-f; else f=; fi
    git add $INPUT_ADD $f
}

remove() {
    if [ -n "$INPUT_REMOVE" ]; then git rm $INPUT_REMOVE; fi
}

commit() {
    if $INPUT_SIGNOFF; then signoffcmd=--signoff; else signoffcmd=; fi
    git commit -m "$INPUT_MESSAGE" --author="$INPUT_AUTHOR_NAME <$INPUT_AUTHOR_EMAIL>" $signoffcmd
}

tag() {
    if [ -n "$INPUT_TAG" ]; then git tag $INPUT_TAG; fi
}

main() {
    # This is needed to make the check work for untracked files
    echo "Staging files..."
    add
    remove
    
    echo "Checking for uncommitted changes in the git working tree..."
    # This section only runs if there have been file changes
    if ! git diff --cached --quiet --exit-code; then
        git_setup
    
        git fetch
    
        # Switch branch (create a new one if it doesn't exist)
        echo "Switching/creating branch..."
        git checkout "$INPUT_REF" 2>/dev/null || git checkout -b "$INPUT_REF"
    
        echo "Pulling from remote..."
        git fetch && git pull
        git pull --tags
    
        echo "Resetting files..."
        git reset
    
        echo "Adding files..."
        add
    
        echo "Removing files..."
        remove
    
        echo "Creating commit..."
        commit
    
        echo "Tagging commit..."
        tag
    
        echo "Pushing commits to repo..."
        git push --set-upstream origin "$INPUT_REF"
    
        echo "Pushing tags to repo..."
        git push --set-upstream origin "$INPUT_REF" --force --tags
    
        echo "Task completed."
    else
        echo "Working tree clean. Nothing to commit."
    fi
}

echo "::endgroup::"

###############################################################################

echo "::group::GITCHANGELOG"
gitchangelog
echo "::endgroup::"

###############################################################################

echo "::group::COMMIT"
INPUT_ADD="$INPUT_VERSIONFILE $INPUT_CHANGELOGFILE"
INPUT_MESSAGE='automatic changelog generation and version increment'
INPUT_TAG=$(source .version && echo $VERSION)
echo $INPUT_MESSAGE
echo $INPUT_TAG
main
echo "::endgroup::"

###############################################################################

echo "::group::CLEANUP"
if [[ "$RC" != "" ]]
then
    echo "Removing $RC"
    rm "$RC"
fi
echo "::endgroup::"

###############################################################################
