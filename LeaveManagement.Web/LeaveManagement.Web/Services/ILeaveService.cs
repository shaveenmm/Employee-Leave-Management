namespace LeaveManagement.Web.Services;

/* The leave actions an employee, manager or HR user can perform. Every
   rule (overlaps, balances, who may approve) is enforced by the stored
   procedures, so each method here only passes values through. When a rule
   is broken the method throws a LeaveProcedureException whose message can
   be shown to the user. */
public interface ILeaveService
{
    // Creates a pending request and returns its new request id.
    Task<int> SubmitLeaveAsync(
        int employeeId,
        int leaveTypeId,
        DateTime startDate,
        DateTime endDate,
        string? reason);

    // Approves a pending request and deducts the days from the balance.
    Task ApproveLeaveAsync(int requestId, int approverId, string? comment);

    // Rejects a pending request. A comment is required.
    Task RejectLeaveAsync(int requestId, int approverId, string comment);

    // Cancels the employee's own request. An approved request can only be
    // cancelled before it starts, and its days go back to the balance.
    Task CancelLeaveAsync(int requestId, int employeeId);
}
