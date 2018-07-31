#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

gh_user=$1
gh_key=$2
gh_repo=$3
base=$4
workspace="workspace_$base"
commits="commits_$base.txt"
log_base_url=${5}
run_command=${6-"./test.sh"}
db=db

if [ -n $LATEST_COMMIT ]; then 
    jq=".sha"
    api="repos/${gh_repo}/commits/${base}"
    git_fetch="${base}"
else    
    jq="map(.head.sha) | .[]"
    api="repos/${gh_repo}/pulls?state=open&base=${base}"
    git_fetch="refs/pull/*/head:refs/remotes/origin/pr/*"
fi

mkdir -p $db
touch $db/$commits

if [ ! -d $workspace ]; then
    git clone --depth 1 git@github.com:$gh_repo $workspace
fi

( cd $workspace && git fetch origin --force -q $git_fetch ) 

shas=`curl -s -u $gh_user:$gh_key "https://api.github.com/$api" | jq -r "$jq"`

function post_status(){
    local sha=$1
    local log_file=$2
    local state=$3
    local desc=$4
    curl -s -u $gh_user:$gh_key -X POST https://api.github.com/repos/${gh_repo}/statuses/${sha} \
    -d "{\"state\":\"${state}\", \"target_url\":\"${log_base_url}/$log_file\", \"description\": \"${desc}\", \"context\":\"CI ${base}\"}" \
    > /dev/null
}

while read -r sha; do
    [[ -z $sha ]] && break
    if ! grep $sha $db/$commits > /dev/null; then
        echo $sha >> $db/$commits
        log_file="${sha}_${base}.txt"
        post_status $sha $log_file "pending" "Pending $(date)"
        echo "Processing ${sha} ..."   
        start_t=$(date +%s)
        if ( ! ( cd $workspace && git checkout -q $sha && $run_command &> "${script_dir}/${db}/$log_file" ) ); then 
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

