FROM mcr.microsoft.com/dotnet/sdk:6.0 as base

# kaniko has a bit of a freakout when trying to pull the pipeline image
# if this image isn't pushed to the registry as well.
# I don't fully currently understand why, something to do with docker compression
