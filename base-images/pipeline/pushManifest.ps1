param (
    [string]$clusterType,
    [string]$deployingWorkflowName,
    [string]$pipelineImage,
    [string]$commitMessage,
    [string]$deployRevision,
    [string]$appName,
    [string]$envname,
    [string]$codeImage,
    [string]$stagingVersion
)

$ErrorActionPreference = "Stop"

if($clusterType -ne "laptop" -and $clusterType -ne "homelab"){
    write-error "cluster type is wrong!"
    exit 1
}

$isTest = $deployRevision -eq "test"

$changeDescription = "$appName - $commitMessage"

$gitToken = $env:GIT_TOKEN
$gitUsername = $env:GIT_USERNAME
$appsRepoName = "homelab-apps"
if($isTest){
    $rootDir = resolve-path "$psscriptroot/../../"
    write-host "$rootDir"
    cd $rootDir
} else {
    write-host "Cloning git repo"
    git clone "https://$gitToken@github.com/$gitUsername/$appsRepoName"
    cd $appsRepoName
}

if($clusterType -eq "laptop"){
    $laptopOrNone = "/laptop"
} else {
    $laptopOrNone = ""
}

$productionManifestsDir = "apps/production/manifests$laptopOrNone"
$stagingManifestsDir = "apps/staging/manifests$laptopOrNone"

$productionManifestPath = "$productionManifestsDir/production.json"
$manifest = Get-Content $productionManifestPath | ConvertFrom-Json

$isProduction = "production" -eq $envname
if($isProduction){
    $manifestPath = $productionManifestPath
} else {
    $manifestPath = "$stagingManifestsDir/$envname.json"
}
write-host "Manifest: $manifestPath"

$manifest.deploying_workflow_name = $deployingWorkflowName
$manifest.envname = $envname
$manifest.change_description = $changeDescription

$theApp = $manifest.apps.$appName
if($theApp -ne $null){
    if("null" -ne $codeImage){
        write-host "Updating code image to $codeImage"
        $theApp.images.code.image = $codeImage
        $theApp.images.code.image_tag = $stagingVersion
    }
    
    $theApp.deploy.revision = $deployRevision
    $theApp.images.pipeline = $pipelineImage
    $theApp.last_change_description = $commitMessage

} else {
    write-error "Cannot get app '$appName'!"
    exit 1
}

$manifest | ConvertTo-Json -Depth 9 | Out-File $manifestPath
cat $manifestPath

if($isProduction){
    write-host "Is production run, delete staging file"
    $stagingVersionPath = "$stagingManifestsDir/$stagingVersion.json"
    if(-not(test-path $stagingVersionPath)){
        write-host "File not found! dont fail pipeline but this isn't good."
    } else {
        rm $stagingVersionPath
    }
}

if($isTest){
    write-host "Testing mode, don't push"
} else {
    git config user.name $env:GIT_NAME
    git config user.email $env:GIT_EMAIL
    
    git status
    git add -A
    git commit -m "$envname - $changeDescription"

    git remote set-url origin "https://$gitUsername`:$gitToken@github.com/$gitUsername/$appsRepoName.git"
    git push
}
