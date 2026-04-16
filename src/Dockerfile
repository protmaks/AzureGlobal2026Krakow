# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY RazorPagesMovie.csproj .
RUN dotnet restore

# Copy everything else and build
COPY . .
RUN dotnet build -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
#EXPOSE 8081

# Copy published app
COPY --from=publish /app/publish .

# Set environment to development by default
ENV ASPNETCORE_ENVIRONMENT=Development
ENV ASPNETCORE_HTTP_PORTS=8080
#ENV ASPNETCORE_HTTPS_PORTS=8081

ENTRYPOINT ["dotnet", "RazorPagesMovie.dll"]
