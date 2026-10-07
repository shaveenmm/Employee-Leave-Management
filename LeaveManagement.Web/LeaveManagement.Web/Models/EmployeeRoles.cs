namespace LeaveManagement.Web.Models;

/* Role values stored in EMPLOYEE.EMPLOYEE_ROLE. These must match the
   check constraint in 01_tables.sql and the role check in the approve
   and reject procedures. */

public static class EmployeeRoles
{
    public const string Employee = "EMPLOYEE";
    public const string Manager = "MANAGER";
    public const string HR = "HR";
}
