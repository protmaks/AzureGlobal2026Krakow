using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using RazorPagesMovie.Data;
using RazorPagesMovie.Models;

namespace RazorPagesMovie.Pages.Movies;

public class IndexModel : PageModel
{
    private readonly RazorPagesMovieContext _context;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;

    public IndexModel(RazorPagesMovieContext context, IConfiguration configuration, IWebHostEnvironment environment)
    {
        _context = context;
        _configuration = configuration;
        _environment = environment;
    }

    public IList<Movie> Movie { get;set; } = default!;
    public string? ConnectionStringError { get; set; }

    public async Task OnGetAsync()
    {
        var connectionString = _configuration.GetConnectionString("RazorPagesMovieContext");
        
        if (!_environment.IsDevelopment() && 
            !string.IsNullOrEmpty(connectionString) &&
            connectionString.Equals("movedToAKV", StringComparison.OrdinalIgnoreCase))
        {
            ConnectionStringError = "Connection string is still set to placeholder value. No datasource is available. Please configure a valid SQL Server connection string.";
            Movie = new List<Movie>();
            return;
        }

        try
        {
            if (_context.Movie != null)
            {
                Movie = await _context.Movie.ToListAsync();
            }
            else
            {
                Movie = new List<Movie>();
            }
        }
        catch (Exception ex)
        {
            ConnectionStringError = $"Database connection error: {ex.Message}";
            Movie = new List<Movie>();
        }
    }
}
