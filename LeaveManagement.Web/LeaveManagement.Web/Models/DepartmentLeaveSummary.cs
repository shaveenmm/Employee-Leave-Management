namespace LeaveManagement.Web.Models;

// One row of VW_LEAVE_SUMMARY: approved leave per department and leave type.
public class DepartmentLeaveSummary
{
    public string Department { get; set; } = string.Empty;
    public string LeaveType { get; set; } = string.Empty;
    public int ApprovedRequests { get; set; }
    public decimal TotalDays { get; set; }
}
