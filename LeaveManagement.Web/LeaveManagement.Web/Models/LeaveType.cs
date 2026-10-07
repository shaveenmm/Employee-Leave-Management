namespace LeaveManagement.Web.Models;

// One row of the LEAVE_TYPE table, for example Annual or Sick leave.
public class LeaveType
{
    public int LeaveTypeId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal DaysPerYear { get; set; }
}
