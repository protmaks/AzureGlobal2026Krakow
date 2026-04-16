using Microsoft.EntityFrameworkCore;
using RazorPagesMovie.Data;
using RazorPagesMovie.Migrations;

var builder = WebApplication.CreateBuilder(args);

// Add Application Insights telemetry
var appInsightsConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
if (!string.IsNullOrEmpty(appInsightsConnectionString) && 
    !appInsightsConnectionString.Equals("movedToAKV", StringComparison.OrdinalIgnoreCase))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnectionString;
    });
}

// Add services to the container.
builder.Services.AddRazorPages();

var connectionString = builder.Configuration.GetConnectionString("RazorPagesMovieContext") 
    ?? throw new InvalidOperationException("Connection string 'RazorPagesMovieContext' not found.");

// Check if connection string is a placeholder
var isPlaceholder = connectionString.Equals("movedToAKV", StringComparison.OrdinalIgnoreCase);

builder.Services.AddDbContext<RazorPagesMovieContext>(options =>
{
    options.UseSqlServer(connectionString);
});


var app = builder.Build();

// Apply migrations if using SQL Server with valid connection string
if (!isPlaceholder)
{
    using (var scope = app.Services.CreateScope())
    {
        var services = scope.ServiceProvider;
        var context = services.GetRequiredService<RazorPagesMovieContext>();
        
        try
        {
            context.Database.Migrate();
        }
        catch (Exception ex)
        {
            var logger = services.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "An error occurred while migrating the database.");
        }
    }
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
