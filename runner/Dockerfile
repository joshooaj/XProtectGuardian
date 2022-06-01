FROM mcr.microsoft.com/windows:20H2

COPY . .
SHELL ["powershell", "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass", "-Command"]
RUN .\prepare.ps1
WORKDIR "C:\\actions-runner\\"
ARG GHURL=""
ARG GHTOKEN=""
ENTRYPOINT ["powershell", "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass", "-File", "..\\run.ps1"]