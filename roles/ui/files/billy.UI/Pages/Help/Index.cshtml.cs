using Microsoft.AspNetCore.Mvc.RazorPages;
using billy.Config.Api;

namespace billy.Ui.Pages.Help
{
    public class MainModel : PageModel
    {
        public UserConfig userConfig { get; set; }

        public MainModel(UserConfig userConfig)
        {
            this.userConfig = userConfig;
        }

        public void OnGet(string lang)
        {
            userConfig.SetLanguage(lang);
        }
    }
}
