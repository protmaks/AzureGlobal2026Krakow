using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using RazorPagesMovie.Data;
using RazorPagesMovie.Models;

namespace RazorPagesMovie.Pages.Movies;

public class CreateModel : PageModel
{
    private readonly RazorPagesMovieContext _context;

    public CreateModel(RazorPagesMovieContext context)
    {
        _context = context;
    }

    public IActionResult OnGet()
    {
        return Page();
    }

    [BindProperty]
    public Movie Movie { get; set; } = default!;

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid || _context.Movie == null || Movie == null)
        {
            return Page();
        }

        _context.Movie.Add(Movie);
        await _context.SaveChangesAsync();

        return RedirectToPage("./Index");
    }
}
