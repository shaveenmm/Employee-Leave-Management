namespace LeaveManagement.Web.Models;

/** One row of VW_PENDING_REQUESTS, used by the manager dashboard.
    ManagerId is the line manager of the employee who made the request,
    so a manager's list is the rows where ManagerId equals their own id. */
public class PendingRequest
{
    public int RequestId { get; set; }
    public int EmployeeId { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public int? ManagerId { get; set; }
    public string LeaveType { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal DaysRequested { get; set; }
    public string? Reason { get; set; }
    public DateTime DateSubmitted { get; set; }
}
