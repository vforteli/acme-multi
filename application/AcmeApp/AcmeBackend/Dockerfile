FROM mcr.microsoft.com/dotnet/sdk:8.0-jammy AS build
ARG TARGET_ARCH=arm64

RUN apt update
RUN apt install -y clang zlib1g-dev

WORKDIR /source

COPY *.sln .

COPY *.csproj ./AcmeBackend/

WORKDIR /source/AcmeBackend
RUN dotnet restore -a $TARGET_ARCH

WORKDIR /source

COPY . ./AcmeBackend/

WORKDIR /source/AcmeBackend
RUN dotnet publish -a $TARGET_ARCH -c Release -o /app --self-contained

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-jammy-chiseled

WORKDIR /app
COPY --from=build /app ./

USER $APP_UID
ENTRYPOINT ["./AcmeBackend"]

EXPOSE 8080