namespace LeaveManagement.Web.Services;

/* Thrown when one of the leave stored procedures rejects an action, for
   example an overlapping request or an approver without permission. The
   message is the text written in the procedure, so it is safe to show to
   the user. ErrorCode is the Oracle application error number, such as
   -20006 for an insufficient balance, which lets callers react to a
   specific rule if they need to. */
public class LeaveProcedureException : Exception
{
    public int ErrorCode { get; }

    public LeaveProcedureException(int errorCode, string message, Exception? innerException = null)
        : base(message, innerException)
    {
        ErrorCode = errorCode;
    }
}
