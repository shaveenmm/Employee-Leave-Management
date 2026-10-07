namespace LeaveManagement.Web.Models;

/* Status values stored in LEAVE_REQUEST.STATUS. These must match the
   check constraint in 01_tables.sql, so change both together. */
public static class LeaveStatus
{
    public const string Pending = "PENDING";
    public const string Approved = "APPROVED";
    public const string Rejected = "REJECTED";
    public const string Cancelled = "CANCELLED";
}
