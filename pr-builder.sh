#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

gh_user=$1
gh_key=$2
gh_repo=$3
base=$4
log_base_url=${5}
context=${6}
run_command=${7-"./test.sh"}
db=db

if [ -z $LATEST_COMMIT ]; then 
    jq="map(.head.sha) | .[]"
    api="repos/${gh_repo}/pulls?state=open&base=${base}"
    git_fetch="refs/pull/*/head:refs/remotes/origin/pr/*"
    ci="${base}"
else
    jq=".sha"
    api="repos/${gh_repo}/commits/${base}"
    git_fetch="${base}"
    ci="${base}_latest"
fi

workspace="workspace_$ci"
commits="commits_$ci.txt"

mkdir -p $db
touch $db/$commits

if [ ! -d $workspace ]; then
    git clone git@github.com:$gh_repo $workspace
fi

( cd $workspace && git fetch origin --force ) 

shas=`curl -s -u $gh_user:$gh_key "https://api.github.com/$api" | jq -r "$jq"`

function post_status(){
    local sha=$1
    local log_file=$2
    local state=$3
    local desc=$4
    curl -s -u $gh_user:$gh_key -X POST https://api.github.com/repos/${gh_repo}/statuses/${sha} \
    -d "{\"state\":\"${state}\", \"target_url\":\"${log_base_url}/$log_file\", \"description\": \"${desc}\", \"context\":\"${context} ${ci}\"}" \
    > /dev/null
}

while read -r sha; do
    [[ -z $sha ]] && break
    if ! grep $sha $db/$commits > /dev/null; then
        log_file="${sha}_${ci}.txt"
        post_status $sha $log_file "pending" "Pending $(date)"
        echo "Processing ${sha} ..."   
        sleep 2 # code isnt' always immediately availabel, even if the gh api says it is
        start_t=$(date +%s)
        if ( ! ( cd $workspace && git checkout -q $sha && echo $sha >> "${script_dir}/$db/$commits" && PR_BUILDER_BASE=$base $run_command &> "${script_dir}/${db}/$log_file" ) ); then 
            echo "Failure"
            end_t=$(date +%s)
            post_status $sha $log_file "failure" "`expr $end_t - $start_t` seconds"
        else
            echo "Success"
            end_t=$(date +%s)
            post_status $sha $log_file "success" "`expr $end_t - $start_t` seconds"
        fi
    else
        echo "Skipping ${sha}"
    fi;
done <<< "$shas"

echo "done."

