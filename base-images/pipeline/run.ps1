# Need to define the scripts below for each app if they are needed
# and run this script as part of the pipeline with flags like:
#   run.ps1 -Migrations
param ([switch]$FunctionalTests, [switch]$Migrations)

if($FunctionalTests){
    $runFile = "/work/functionalTests.ps1"
    if(-not(test-path $runFile)){
        write-host "No file present at: '$runFile', don't run functional tests."
        exit 0
    } else {
        write-host "Running functional tests"
        pwsh -file $runFile
        exit $LASTEXITCODE
    }
}

if($Migrations){
    $runFile = "/work/migrations.ps1"
    if(-not(test-path $runFile)){
        write-host "No file present at: '$runFile', don't run migrations."
        exit 0
    } else {
        write-host "Running migrations"
        pwsh -file $runFile
        exit $LASTEXITCODE
    }
}
