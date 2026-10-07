using Oracle.ManagedDataAccess.Client;

namespace LeaveManagement.Web.Data;

/* Creates Oracle connections for the data access classes. Keeping this
   behind an interface means the services never read configuration
   themselves, and tests can supply their own implementation. */
public interface IOracleConnectionFactory
{
    /* Returns a new connection that has not been opened yet. The caller
       owns it, so open it with OpenAsync and dispose it when finished,
       normally with a using statement. */
    OracleConnection Create();
}