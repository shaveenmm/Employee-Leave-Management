using Oracle.ManagedDataAccess.Client;

namespace LeaveManagement.Web.Services;

/* The stored procedures report rule violations with RAISE_APPLICATION_ERROR,
   which Oracle delivers to C# as an OracleException numbered between 20000
   and 20999. This class turns those into a LeaveProcedureException carrying
   just the readable message, and leaves every other database error alone so
   real faults such as a lost connection are not mistaken for a broken rule. */
public static class OracleErrorTranslator
{
    // Returns null when the error is not one of the application errors raised by the leave procedures.
    public static LeaveProcedureException? Translate(OracleException exception)
    {
        if (exception.Number < 20000 || exception.Number > 20999)
        {
            return null;
        }

        /* Oracle formats the message as "ORA-20006: text" followed by extra
           lines such as ORA-06512 that point at the line in the procedure.
           Only the first line holds the text written in the procedure. */
        var message = exception.Message;
        var prefix = $"ORA-{exception.Number}:";
        var prefixPosition = message.IndexOf(prefix, StringComparison.Ordinal);

        if (prefixPosition >= 0)
        {
            message = message[(prefixPosition + prefix.Length)..];
        }

        var lineEnd = message.IndexOf('\n');
        if (lineEnd >= 0)
        {
            message = message[..lineEnd];
        }

        // The procedures document their codes as negative numbers, for
        // example -20006, so the exception is given the same sign.
        return new LeaveProcedureException(-exception.Number, message.Trim(), exception);
    }
}