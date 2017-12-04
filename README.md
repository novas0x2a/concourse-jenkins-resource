# Jenkins Resource

Triggers and monitors jenkins builds. This isn't a super in-depth implementation, so beware :)

## Installation
Add a new resource type to your Concourse CI pipeline:
```yaml
resource_types:
- name: jenkins
 type: docker-image
 source:
   repository: novas0x2a/concourse-jenkins-resource
   tag: latest # For reproducible builds use a specific tag and don't rely on "latest".
```

## Source Configuration

* `host`: *Required.* Hostname for jenkins
* `user`: *Required.* Username for jenkins
* `pass`: *Required.* Password for jenkins
* `job`: *Required.* The path within jenkins for the specific job you want to
  monitor/trigger; the easiest way to get this path is to browse to the job in
  question in jenkins, and copy the url. (Not everything is a job; you'll know
  you're in the right place if you see a "Build Now" or "Build with Parameters"
  link. A correct path will look like `/job/subdir/job/otherdir/job/my-cool-job`)

## Behavior

### `check`: check for new builds.

The ids of the resource versions will match the jenkins ids for the builds.

### out: Trigger a build

This will start a jenkins job, and will wait until jenkins assigns it a job id.
(It will not wait for the job to complete; you can use
[get_params](https://concourse.ci/put-step.html) and `requireResult` on the
`get` side for that.

#### Parameters
* `buildParams`: If you set this to a string, the build trigger will use
  `buildWithParameters` instead of `build` and will send buildParams as the
  postdata. Example: `buildType=full&bestAnimal=cat`


### in: Fetch result of a jenkins job

This will get the status information of a specific build of the job.

The following files will be placed in the destination:

* `/raw`: The exact json api data jenkins returned.
* `/result`: The result string, as jenkins reported it
* `/url`: The full url to the build.
* `/start_time_ms`: The start time of the build, in unix time, in ms
* `/start_time_s`: The start time of the build, in unix time, in s

#### Parameters
* `requireResult`: If you set this to a string, the get will block until the
  job has completed, and the success of the get will depend on the job's result
  (case-sensitive); `requireResult: SUCCESS` will indicate that you want the
  concourse get to succeed iff the job is completed _and_ the jenkins build
  result is SUCCESS. (The default list of results is [SUCCESS, UNSTABLE,
  FAILURE, NOT_BUILT, ABORTED], but plugins can add more).


## Full example

 ```yaml
resource_types:
 - name: jenkins
  type: docker-image
  source:
    repository: novas0x2a/concourse-jenkins-resource
    tag: latest # For reproducible builds use a specific tag and don't rely on "latest".

resources:
- name: my-cool-job
  type: jenkins
  source:
    host: jenkins.company.com
    job: /job/my-group/job/my-cool-job
    user: ((jenkins.user))
    pass: ((jenkins.pass))

jobs:

- name: build-nonblocking
  plan:
  - put: my-cool-job

- name: build-blocking
  plan:
  - put: my-cool-job
    get_params:
        requireResult: SUCCESS

- name: build-with-params
  plan:
  - put: my-cool-job
    params:
        buildParams: buildType=full&bestAnimal=cat
```
