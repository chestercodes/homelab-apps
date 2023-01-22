namespace workflow_reporter

#nowarn "20"

open System
open System.Collections.Generic
open System.Linq
open Microsoft.AspNetCore.Builder
open Microsoft.Extensions.Hosting
open System.Collections.Concurrent
open System.Net.Http

module ArgoWorkflowApi =
    let makeCall endOfUrl =
        fun workflowName ->
            task {
                use client = new HttpClient()
                let b = Environment.GetEnvironmentVariable("WORKFLOWS_BASE_URL")

                let baseUrl =
                    if b <> null then
                        b
                    else
                        "http://argo-workflows-server.pipeline.svc.cluster.local:2746"

                try
                    let! response =
                        let url = sprintf "%s/api/v1/workflows/pipeline/%s/%s" baseUrl workflowName endOfUrl
                        printfn "Calling PUT to %s" url
                        client.PutAsync(url, null)

                    ()
                with ex ->
                    printfn "%A" ex //ex is any exception
                    ()

                ()
            }
            |> Async.AwaitTask
            |> Async.RunSynchronously


    let callProceed (workflowName: string) =
        printfn "Call proceed!"
        makeCall "resume" workflowName

    let callAbort (workflowName: string) =
        printfn "Call abort!"
        makeCall "stop" workflowName


module WorkflowReport =

    [<CLIMutable>]
    type SubmitWorkflowApiModel =
        { WorkflowName: string; Apps: string[] }

    [<CLIMutable>]
    type UpdateWorkflowApiModel =
        { WorkflowName: string
          App: string
          Success: bool }

    let workflowSubmit (state: ConcurrentDictionary<string, SubmitWorkflowApiModel>) =
        fun (model: SubmitWorkflowApiModel) ->
            printfn "Workflow submitted: %A" model

            if state.ContainsKey(model.WorkflowName) then
                printfn "Already contain workflow %s" model.WorkflowName
            else if state.TryAdd(model.WorkflowName, model) then
                printfn "Added %s" model.WorkflowName
            else
                printfn "Failed for some reason :("

            "ok"

    let workflowUpdate (state: ConcurrentDictionary<string, SubmitWorkflowApiModel>) callProceed callAbort =
        fun (model: UpdateWorkflowApiModel) ->
            printfn "Workflow updated: %A" model

            if not model.Success then
                callAbort model.WorkflowName
            else
                let v = state.GetValueOrDefault(model.WorkflowName)

                if v.Apps.Contains(model.App) then
                    let newApps = v.Apps |> Array.filter (fun x -> x <> model.App)

                    if newApps.Length = 0 then
                        printfn "All apps received, call proceed"
                        callProceed model.WorkflowName
                        state.Remove(model.WorkflowName, ref v) |> ignore
                    else
                        let newSubmit =
                            { WorkflowName = model.WorkflowName
                              Apps = newApps }

                        state.TryUpdate(model.WorkflowName, newSubmit, v) |> ignore
                else
                    printfn "Reported app doesn't exist in submitted apps, ignore."

            "ok"

module Program =
    open WorkflowReport
    open ArgoWorkflowApi

    [<EntryPoint>]
    let main args =
        let builder = WebApplication.CreateBuilder()
        let app = builder.Build()

        let state = new ConcurrentDictionary<string, SubmitWorkflowApiModel>()

        app.MapGet("/health", Func<string>(fun () -> "I'm good cheers")) |> ignore

        app.MapPost("/workflow/submit", Func<SubmitWorkflowApiModel, string>(workflowSubmit state))
        |> ignore

        app.MapPost(
            "/workflow/update",
            Func<UpdateWorkflowApiModel, string>(workflowUpdate state callProceed callAbort)
        )
        |> ignore

        app.Run()
        0
