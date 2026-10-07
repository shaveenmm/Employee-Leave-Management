namespace LeaveManagement.Web.Models;

// Single row of the EMPLOYEE table.
public class Employee
{
    public int EmployeeId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public string Role { get; set; } = EmployeeRoles.Employee;
    public int? ManagerId { get; set; }
    public DateTime HireDate { get; set; }
    public bool IsActive { get; set; }

    public string FullName => $"{FirstName} {LastName}";
}