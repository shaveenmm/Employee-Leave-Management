using LeaveManagement.Web.Data;
using LeaveManagement.Web.Services;

namespace LeaveManagement.Web
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            builder.Services.AddControllersWithViews();

            /* The factory only holds the connection string, so one shared
               instance is enough. Each data access call asks it for its own
               short-lived connection. */
            builder.Services.AddSingleton<IOracleConnectionFactory, OracleConnectionFactory>();

            /* The leave service keeps no state between calls, and a new one
               per request is the usual lifetime for services that use the
               database. */
            builder.Services.AddScoped<ILeaveService, LeaveService>();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Home/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthorization();

            app.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");

            app.Run();
        }
    }
}
