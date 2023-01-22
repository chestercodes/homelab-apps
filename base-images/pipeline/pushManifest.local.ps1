
pwsh -file "$psscriptroot/pushManifest.ps1" -clusterType "laptop" `
    -deployingWorkflowName "workflow-123" -pipelineImage "pipeline:123" `
    -commitMessage "this commit" `
    -deployRevision "test" -appName "homelabping" -envname "stag" -codeImage "null"
