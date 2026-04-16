using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace RazorPagesMovie.Pages;

public class ProductionModel : PageModel
{
    private readonly ILogger<ProductionModel> _logger;
    private readonly IWebHostEnvironment _environment;
    private readonly IConfiguration _configuration;

    public ProductionModel(ILogger<ProductionModel> logger, IWebHostEnvironment environment, IConfiguration configuration)
    {
        _logger = logger;
        _environment = environment;
        _configuration = configuration;
    }

    public string? AzureKeyVaultSecret { get; set; }
    public string? SecretStatus { get; set; }

    public IActionResult OnGet()
    {
        if (_environment.IsDevelopment())
        {
            return NotFound();
        }

        // Try to get secret from Azure Key Vault (optional)
        try
        {
            AzureKeyVaultSecret = _configuration["AzureKeyVault:SecretKey"];
            
            if (string.IsNullOrEmpty(AzureKeyVaultSecret))
            {
                SecretStatus = "Not configured";
            }
            else
            {
                SecretStatus = "Retrieved successfully";
            }
        }
        catch (Exception ex)
        {
            SecretStatus = $"Error: {ex.Message}";
        }

        return Page();
    }
}
