#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Container image that runs your code
FROM cloudnativeofalibabacloud/test-runner:v0.0.1

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entry.sh /entry.sh
RUN chmod -x /entry.sh

# Code file to execute when the docker container starts up (`entry.sh`)
ENTRYPOINT ["/entry.sh"]
