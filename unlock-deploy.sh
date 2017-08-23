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
source "sourced.sh"

if [ "--force" == "$1" ] ; then
    deploy_unlock_locally
fi

if [ "yes" == "$(deploy_is_locally_locked)" ] ; then
    announce
    announce "Deploy is locked locally. Cannot unlock. Use --force to override."
    announce
else
    announce "Unlocking the deploy"
    deploy_unlock
fi


