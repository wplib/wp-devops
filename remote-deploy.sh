#!/usr/bin/env bash
#
#    Copyright 2018 NewClarity Consulting, LLC
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

echo "Triggering remote build at CircleCI."
pushd ../.. > /dev/null
CIRCLE_TOKEN="$(cat .circleci/circleci.token)"
LATEST_COMMIT="$(git log -1 --pretty=format:"%H")"
REPO_REF="$(git remote -v | grep push | awk '{print $2}' | sed 's/git\@//' | sed 's/:/\//' | sed 's/\.git//' | sed 's/\.com//')"
BRANCH_NAME="$(git branch | grep '*' | awk '{print $2}')"

curl \
    --silent \
    --user "${CIRCLE_TOKEN}": \
    --request POST \
    --form revision="${LATEST_COMMIT}" \
    --form config=../config.yml \
    --remote-name \
    --form notify=false \
        "https://circleci.com/api/v1.1/project/${REPO_REF}/tree/${BRANCH_NAME}"

mkdir -p .circleci/logs
rm -rf .circleci/logs/LAST_BUILD.json
mv "${BRANCH_NAME}" .circleci/logs/LAST_BUILD.json
cat .circleci/logs/LAST_BUILD.json | jq -r '.messages[].message' | sed -e 's/<[a-zA-Z\/][^>]*>//g'
popd > /dev/null
echo "Done."
