namespace LeaveManagement.Web.Models;

// One row of VW_TEAM_CALENDAR, which lists approved leave only.
public class TeamCalendarEntry
{
    public int RequestId { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public int? ManagerId { get; set; }
    public string LeaveType { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal DaysRequested { get; set; }
}
