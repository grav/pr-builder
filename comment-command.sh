#!/bin/bash

set -e

gh_user=$1
gh_key=$2
gh_repo=$3 # eg grav/my-repo
command=$4 # what to look for in comments, eg `compare_to`
run_cmd=$5 # what to run in repo, eg `./compare.sh`
log_base_url=${6} # where to post status
workspace=workspace
db=db
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p $db
touch $db/comments.txt

function extract_commands(){
    local command=$1
    jq -r ".data.repository.pullRequests.edges[] | {sha: .node.commits.edges[0].node.commit.oid , comments: (.node.comments.edges | map({body: .node.body, id: .node.id}) | .[] | select(.body | contains(\"$command\")) )} | \"\\(.sha)|\\(.comments.id)|\\(.comments.body)\""
}

function get_comments_for_prs(){
    # OLDIFS=$IFS
    IFS=/ read owner repo <<< "$gh_repo"
    # IFS=$OLDIFS
    curl -s -u $gh_user:$gh_key "https://api.github.com/graphql" -X POST -d "{\"query\":\"{\n  repository(owner: \\\"$owner\\\", name: \\\"$repo\\\") {\n    pullRequests(states: [OPEN], first: 100) {\n      edges {\n        node {\n          commits(last: 1) {\n            edges {\n              node {\n                commit {\n                  oid\n                }\n              }\n            }\n          }\n          comments(first: 100) {\n            edges {\n              node {\n                body\n                id\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n}\n\n\",\"variables\":\"{}\",\"operationName\":null}"
} 

function post_status(){
    local sha=$1
    local arg=$2
    local logfile=$3
    local state=$4
    local desc=$5
    curl -s -u $gh_user:$gh_key -X POST https://api.github.com/repos/${gh_repo}/statuses/${sha} \
    -d "{\"state\":\"${state}\", \"target_url\":\"${log_base_url}/${logfile}\", \"description\": \"${desc}\", \"context\":\"${command} ${arg}\"}" \
    > /dev/null
}

if [ ! -d $workspace ]; then
    git clone --depth 1 git@github.com:$3 workspace
fi

( cd $workspace && git fetch origin --force -q refs/pull/*/head:refs/remotes/origin/pr/* ) 

commands=`get_comments_for_prs | extract_commands "$command" | grep .`

while read -r line; do
    IFS=\| read sha comment_id text <<< "$line"
    if ! grep $comment_id $db/comments.txt > /dev/null; then
        arg=`echo "$text" | cut -d\  -f2`
        log_file="${command}_${sha}_${arg}.txt"
        echo $comment_id >> $db/comments.txt
        post_status $sha $arg $log_file "pending" "Pending"
        echo "$command $sha $arg"
        start_t=$(date +%s)
        if ( ! ( cd $workspace && git checkout -q $sha && $run_cmd $sha $arg &> "${script_dir}/${db}/${log_file}" ) ); then 
            echo "Failure"
            post_status $sha $arg $log_file "failure" "Failure"
        else
            echo "Success"
            end_t=$(date +%s)
            post_status $sha $arg $log_file "success" "`expr $end_t - $start_t` seconds"
        fi
    else
        echo "Skipping $sha: '$text'"
    fi
done <<< "$commands"
