namespace LeaveManagement.Web.Models;

/* One row of the LEAVE_REQUEST table, with the leave type name joined in
   so screens do not need a second lookup. */
public class LeaveRequest
{
    public int RequestId { get; set; }
    public int EmployeeId { get; set; }
    public int LeaveTypeId { get; set; }
    public string LeaveTypeName { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal DaysRequested { get; set; }
    public string? Reason { get; set; }
    public string Status { get; set; } = LeaveStatus.Pending;
    public string? ManagerComment { get; set; }
    public DateTime DateSubmitted { get; set; }
    public int? DecidedBy { get; set; }
    public DateTime? DecidedOn { get; set; }
}
