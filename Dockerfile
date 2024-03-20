FROM mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
# Install .NET Core Runtime
RUN PowerShell Set-ExecutionPolicy Bypass -Scope Process -Force;[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;$env:chocolateyUseWindowsCompression = 'true'; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
RUN PowerShell choco install dotnetcore-sdk --version 2.2.402 -y
RUN powershell -Command $ProgressPreference = 'SilentlyContinue'; Set-ExecutionPolicy Bypass -Scope Process -Force;[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri https://dot.net/v1/dotnet-install.ps1 -OutFile dotnet-install.ps1;./dotnet-install.ps1 -InstallDir '/Program Files/dotnet' -Channel 6.0; -Runtime aspnetcore; Remove-Item -Force dotnet-install.ps1 && SETX /M PATH "%PATH%;C:\Program Files\dotnet"

FROM mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019 AS build
WORKDIR /src
# Install .NET Core SDK
RUN powershell -Command $ProgressPreference = 'SilentlyContinue'; Set-ExecutionPolicy Bypass -Scope Process -Force;[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri https://dot.net/v1/dotnet-install.ps1 -OutFile dotnet-install.ps1; ./dotnet-install.ps1 -InstallDir '/Program Files/dotnet' -Channel 6.0; Remove-Item -Force dotnet-install.ps1 && SETX /M PATH "%PATH%;C:\Program Files\dotnet"

COPY WindowsWebApi/ WindowsWebApi/
# Dev Copies
#COPY NuGet.config MathPrintApi.Web/
# End Dev Copies

ENV NUGET_EXPERIMENTAL_CHAIN_BUILD_RETRY_POLICY=3,1000

RUN dotnet restore WindowsWebApi/WindowsWebApi.csproj

COPY . .

WORKDIR /src/WindowsWebApi/WindowsWebApi
#RUN dotnet build MathPrintApi.Web.csproj -c Release -o /app

FROM build AS publish
RUN dotnet publish WindowsWebApi/WindowsWebApi.csproj -c Release -o /app --no-restore
WORKDIR /app
RUN del NuGet.config

FROM base AS final
WORKDIR /app
#COPY BuildResources/*.dat README.md /app/
#COPY BuildResources/*.DAT README.md /app/
#COPY BuildResources/*.dll README.md /app/
#COPY BuildResources/*.DLL README.md /app/
COPY --from=publish /app .
RUN SETX ASPNETCORE_URLS "http://+"
ENTRYPOINT ["powershell", "Set-TimeZone", "-Name 'Central Standard Time'", ";"]
CMD ["dotnet", "WindowsWebApi/WindowsWebApi.dll"]
