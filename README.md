# homelab-apps

Repo that stores code and config for app build and deployment orchestration and versioning.

The following is an explanation of the folders

### apps

the apps folder includes argo-cd `Application` files that define the deployed applications.

there are seperate folders for production and multiple staging environments, each of these has manifests in the form of json files which define the versions of the deployed code.

### base-images

the applications are deployed with a continuous deployment pipeline which uses a `pipeline` base image to store deployment code. 

each application defines a pipeline docker image tag which is used along each stage of the pipeline and can optionally run migration code and functional tests.

the pipeline image also contains a script that the pipeline invokes to perform manifest file creation

### cloudflared-tunnel

this folder contains code that describes the tunnel into the cluster from the outside world. this is used to direct traffic to the ping app and also used by the github webhook to trigger builds

### pipeline

the pipeline folder stores the argo-events and argo-workflows files that are used to build and deploy the apps

### workflow-reporter

the workflow reporter is a simple app that forms part of the pipeline

when an app finishes deploying the sync trigger calls this project and if all of the apps have deployed successfully the reporter will tell the waiting deployment pipeline to carry on to the migrations or functional tests. if any of the apps fail then the reporter will stop the pipeline.


## interesting features

- argo workflows submitting other workflows
- different manifest folders for cluster types
- pipeline creates staging manifest file which spins up environment to run tests on and waits for environment to be ready. then deletes environment when is finished
- limit argo events pipeline triggering for specific folders in repository and only main branch
- workflow-reporter api tracks which apps have sync-ed when deploying environment and can resume paused pipelines until environment is ready


## deploying images from the homelab registry

argo cd or workflows don't seem to like deploying container images that don't use https

to get around this it's required to user `cert-manager` to give the registry ingress a certificate from lets encrypt. this is only used internally and doesn't see the outside world.