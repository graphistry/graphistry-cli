# Graphistry in Helm: Environment Setup Instructions and useful commands

In this section, we will discuss how to install Graphistry in a Helm chart, start dev mode, recover a released PVC, and more.


# Going from a branch to a box
To go from branch into box, change tag in VERSION & versions/*  push your branch and make a PR, then label with ci-dev label in the PR to run the ci-dev.yml which then pushes your build to graphistry's dev dockerhub. Once this is done your build will be in the dev dockerhub. 


    git clone https://github.com/graphistry/graphistry-helm && cd graphistry-helm

Once in the helm chart folder, change the ```--set tag=v2.39.17-koa-sso``` to the tag of your latest dev build and then run  run the following command to install the chart:

    helm upgrade -i  g-chart ./charts/graphistry-helm  --set tag=<LATEST DEV TAG> --set domain=eks-skinny.grph.xyz --namespace graphistry  --set tls=true --set devMode=true --set nodeEnv=development --set appEnvironment=development --set djangoSettingsModule="config.settings.dev" --set graphistryCPUMode="1" --set djangoDebug=True  --create-namespace





# changing 1 thing vs all, including state 





# Looking at logs

To look at logs of a running container on the cluster, run the following command:

    kubectl get pod -n graphistry


to get the name of the pod you want to look at logs for.

then run the following command:

    kubectl logs <pod-name> -n graphistry



# checking health

To check the health of a pod running in the graphistry cluster run the following command:
    
    kubectl get pods -n graphistry

to get the name of the pod you want to look at logs for.

then run the following command:

    kubectl describe pod <pod-name> -n graphistry
    