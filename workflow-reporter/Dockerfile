FROM mcr.microsoft.com/dotnet/sdk:6.0 as base

WORKDIR /src

RUN mkdir /publish

COPY workflow-reporter.fsproj workflow-reporter.fsproj
COPY Program.fs Program.fs
COPY appsettings.json appsettings.json

RUN dotnet publish -c Release -o /publish

FROM mcr.microsoft.com/dotnet/aspnet:6.0 as runtime

WORKDIR /app

COPY --from=base /publish /app

ENTRYPOINT ["dotnet", "workflow-reporter.dll"]
