namespace LeaveManagement.Web.Models;

/* An employee's balance for one leave type in one year. DaysRemaining is
   what is stored in LEAVE_BALANCE and only drops when a request is
   approved. PendingDays is the total of requests still waiting for a
   decision, which sp_submit_leave also counts against the balance, so
   DaysAvailable is the figure to show on the request form. */

public class LeaveBalance
{
    public int EmployeeId { get; set; }
    public int LeaveTypeId { get; set; }
    public string LeaveTypeName { get; set; } = string.Empty;
    public int BalanceYear { get; set; }
    public decimal DaysRemaining { get; set; }
    public decimal PendingDays { get; set; }

    public decimal DaysAvailable => DaysRemaining - PendingDays;
}
