using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using billy.Logging;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace billy.Ui
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // Implicitly call static constructor so backround lock process is started
            // (static constructor is only called after class is used in any way)
            Log.WriteInfo("Startup", "Starting billy UI Server...");
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args)
        {
            return Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
					webBuilder.UseStaticWebAssets();
					webBuilder.UseStartup<Startup>();
                });
        }
    }
}
