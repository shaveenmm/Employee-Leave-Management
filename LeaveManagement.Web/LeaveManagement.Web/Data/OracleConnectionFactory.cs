using Microsoft.Extensions.Configuration;
using Oracle.ManagedDataAccess.Client;

namespace LeaveManagement.Web.Data;

/* Builds connections from the "OracleDb" connection string. The value is
   kept out of source control and supplied through .NET User Secrets, as
   described in the README. ODP.NET pools connections by default, so
   creating one per operation is cheap and is the intended way to use it. */
public class OracleConnectionFactory : IOracleConnectionFactory
{
    private readonly string _connectionString;

    public OracleConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("OracleDb")
            ?? throw new InvalidOperationException(
                "The connection string 'OracleDb' was not found. " +
                "Set it with dotnet user-secrets, as described in the README.");
    }

    public OracleConnection Create()
    {
        return new OracleConnection(_connectionString);
    }
}
