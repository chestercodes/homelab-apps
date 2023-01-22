FROM mcr.microsoft.com/dotnet/sdk:6.0 as pipeline

ENV PATH="$PATH:/root/.dotnet/tools"

RUN mkdir /work
WORKDIR /work

COPY run.ps1 run.ps1
COPY pushManifest.ps1 pushManifest.ps1

CMD ["sh", "cat run.ps1"]
