using System.Data;
using LeaveManagement.Web.Data;
using Oracle.ManagedDataAccess.Client;

namespace LeaveManagement.Web.Services;

/* Calls the leave stored procedures defined in 03_procedures.sql. The
   procedures commit and roll back on their own, so no transaction is
   managed here. */
public class LeaveService : ILeaveService
{
    private readonly IOracleConnectionFactory _connectionFactory;

    public LeaveService(IOracleConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<int> SubmitLeaveAsync(
        int employeeId,
        int leaveTypeId,
        DateTime startDate,
        DateTime endDate,
        string? reason)
    {
        OracleParameter? requestIdParameter = null;

        await ExecuteProcedureAsync("sp_submit_leave", command =>
        {
            command.Parameters.Add("p_employee_id", OracleDbType.Int32).Value = employeeId;
            command.Parameters.Add("p_leave_type_id", OracleDbType.Int32).Value = leaveTypeId;
            command.Parameters.Add("p_start_date", OracleDbType.Date).Value = startDate;
            command.Parameters.Add("p_end_date", OracleDbType.Date).Value = endDate;
            command.Parameters.Add("p_reason", OracleDbType.Varchar2, 250).Value =
                (object?)reason ?? DBNull.Value;

            requestIdParameter = command.Parameters.Add(
                "p_request_id", OracleDbType.Int32, ParameterDirection.Output);
        });

        // The output value comes back as an Oracle number type, so it is
        // read through its text form to get a plain int.
        return int.Parse(requestIdParameter!.Value.ToString()!);
    }

    public async Task ApproveLeaveAsync(int requestId, int approverId, string? comment)
    {
        await ExecuteProcedureAsync("sp_approve_leave", command =>
        {
            command.Parameters.Add("p_request_id", OracleDbType.Int32).Value = requestId;
            command.Parameters.Add("p_approver_id", OracleDbType.Int32).Value = approverId;
            command.Parameters.Add("p_comment", OracleDbType.Varchar2, 250).Value =
                (object?)comment ?? DBNull.Value;
        });
    }

    public async Task RejectLeaveAsync(int requestId, int approverId, string comment)
    {
        await ExecuteProcedureAsync("sp_reject_leave", command =>
        {
            command.Parameters.Add("p_request_id", OracleDbType.Int32).Value = requestId;
            command.Parameters.Add("p_approver_id", OracleDbType.Int32).Value = approverId;
            command.Parameters.Add("p_comment", OracleDbType.Varchar2, 250).Value = comment;
        });
    }

    public async Task CancelLeaveAsync(int requestId, int employeeId)
    {
        await ExecuteProcedureAsync("sp_cancel_leave", command =>
        {
            command.Parameters.Add("p_request_id", OracleDbType.Int32).Value = requestId;
            command.Parameters.Add("p_employee_id", OracleDbType.Int32).Value = employeeId;
        });
    }

    /* Opens a connection, runs the named procedure with the parameters the
       caller adds, and converts rule violations into LeaveProcedureException.
       Parameters are bound by name so their order does not matter. */
    private async Task ExecuteProcedureAsync(string procedureName, Action<OracleCommand> addParameters)
    {
        using var connection = _connectionFactory.Create();
        await connection.OpenAsync();

        using var command = connection.CreateCommand();
        command.CommandText = procedureName;
        command.CommandType = CommandType.StoredProcedure;
        command.BindByName = true;
        addParameters(command);

        try
        {
            await command.ExecuteNonQueryAsync();
        }
        catch (OracleException ex)
        {
            var translated = OracleErrorTranslator.Translate(ex);

            if (translated is null)
            {
                throw;
            }

            throw translated;
        }
    }
}
