#!/bin/bash

set -e

gh_user=$1
gh_key=$2
gh_repo=$3
workspace=workspace
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p db
touch db/commits.txt

if [ ! -d $workspace ]; then
    git clone --depth 1 git@github.com:$3 workspace
fi

( cd $workspace && git fetch origin --force -q refs/pull/*/head:refs/remotes/origin/pr/* ) 

shas=`curl -s -u $gh_user:$gh_key "https://api.github.com/repos/${gh_repo}/pulls?state=open" | jq -r 'map(.head.sha) | .[]'`

function post_status(){
    local sha=$1
    local state=$2
    local desc=$3
    local url=${4-"http://dr.dk"}
    curl -s -u $gh_user:$gh_key -X POST https://api.github.com/repos/${gh_repo}/statuses/${sha} \
    -d "{\"state\":\"${state}\", \"target_url\":\"http://dr.dk\", \"description\": \"${desc}\", \"context\":\"CI\"}" \
    > /dev/null
}

while read -r sha; do
    if ! grep $sha db/commits.txt > /dev/null; then
        echo $sha >> db/commits.txt
        post_status $sha "pending" "Pending"
        echo "Testing ${sha} ..."   
        if ( ! ( cd $workspace && git checkout -q $sha && ./test.sh 10 > "${script_dir}/db/${sha}.txt" ) ); then 
            echo "Failure"
            post_status $sha "failure" "Failure"
        else
            echo "Success"
            post_status $sha "success" "Success"
        fi
    else
        echo "Skipping ${sha}"
    fi;
done <<< "$shas"

echo "done."

