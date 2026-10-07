-- 03_procedures.sql
-- Business rules: working days, submit, approve, reject, cancel
-- Run after 02_triggers_views.sql

-- Error codes raised (for the C# layer to catch):
--   -20001 to -20006  submit rules
--   -20010 to -20015  approve rules
--   -20020 to -20024  reject rules
--   -20030 to -20032  cancel rules

-- Counts working days between two dates (inclusive),
-- skipping Saturdays, Sundays and rows in PUBLIC_HOLIDAY

CREATE OR REPLACE FUNCTION fn_working_days (
  p_start IN DATE,
  p_end   IN DATE
) RETURN NUMBER
IS
  v_days     NUMBER := 0;
  v_day      DATE   := TRUNC(p_start);
  v_holiday  NUMBER;
BEGIN
  WHILE v_day <= TRUNC(p_end) LOOP
    IF TO_CHAR(v_day, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') NOT IN ('SAT', 'SUN') THEN
      SELECT COUNT(*) INTO v_holiday
      FROM   public_holiday
      WHERE  holiday_date = v_day;

      IF v_holiday = 0 THEN
        v_days := v_days + 1;
      END IF;
    END IF;
    v_day := v_day + 1;
  END LOOP;

  RETURN v_days;
END fn_working_days;
/

-- Submit a leave request
-- Rules: valid dates, same calendar year, at least one working day,
--        no overlap with pending/approved leave, enough balance
--        (pending requests count against the balance)

CREATE OR REPLACE PROCEDURE sp_submit_leave (
  p_employee_id    IN  NUMBER,
  p_leave_type_id  IN  NUMBER,
  p_start_date     IN  DATE,
  p_end_date       IN  DATE,
  p_reason         IN  VARCHAR2,
  p_request_id     OUT NUMBER
)
AS
  v_start    DATE := TRUNC(p_start_date);
  v_end      DATE := TRUNC(p_end_date);
  v_year     NUMBER := EXTRACT(YEAR FROM p_start_date);
  v_days     NUMBER;
  v_balance  NUMBER;
  v_pending  NUMBER;
  v_overlap  NUMBER;
BEGIN
  IF v_end < v_start THEN
    RAISE_APPLICATION_ERROR(-20001, 'End date cannot be before start date.');
  END IF;

  IF EXTRACT(YEAR FROM v_end) <> v_year THEN
    RAISE_APPLICATION_ERROR(-20002, 'Please split requests that span two calendar years.');
  END IF;

  v_days := fn_working_days(v_start, v_end);
  IF v_days = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'The selected dates contain no working days.');
  END IF;

  SELECT COUNT(*) INTO v_overlap
  FROM   leave_request
  WHERE  employee_id = p_employee_id
  AND    status IN ('PENDING', 'APPROVED')
  AND    start_date <= v_end
  AND    end_date   >= v_start;

  IF v_overlap > 0 THEN
    RAISE_APPLICATION_ERROR(-20004, 'This request overlaps with existing leave.');
  END IF;

  BEGIN
    SELECT days_remaining INTO v_balance
    FROM   leave_balance
    WHERE  employee_id   = p_employee_id
    AND    leave_type_id = p_leave_type_id
    AND    balance_year  = v_year;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'No leave balance found for this employee, leave type and year.');
  END;

  SELECT NVL(SUM(days_requested), 0) INTO v_pending
  FROM   leave_request
  WHERE  employee_id   = p_employee_id
  AND    leave_type_id = p_leave_type_id
  AND    status        = 'PENDING'
  AND    EXTRACT(YEAR FROM start_date) = v_year;

  IF v_days > (v_balance - v_pending) THEN
    RAISE_APPLICATION_ERROR(-20006, 'Insufficient leave balance for this request.');
  END IF;

  INSERT INTO leave_request
         (employee_id, leave_type_id, start_date, end_date, days_requested, reason)
  VALUES (p_employee_id, p_leave_type_id, v_start, v_end, v_days, p_reason)
  RETURNING request_id INTO p_request_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_submit_leave;
/

-- Approve a request and deduct the balance in ONE transaction
-- Only the employee's manager or an HR user may approve,
-- and nobody may approve their own request

CREATE OR REPLACE PROCEDURE sp_approve_leave (
  p_request_id  IN NUMBER,
  p_approver_id IN NUMBER,
  p_comment     IN VARCHAR2 DEFAULT NULL
)
AS
  v_req     leave_request%ROWTYPE;
  v_mgr_id  employee.manager_id%TYPE;
  v_role    employee.employee_role%TYPE;
BEGIN
  BEGIN
    SELECT * INTO v_req
    FROM   leave_request
    WHERE  request_id = p_request_id
    FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20010, 'Leave request not found.');
  END;

  IF v_req.status <> 'PENDING' THEN
    RAISE_APPLICATION_ERROR(-20011, 'Only pending requests can be approved.');
  END IF;

  BEGIN
    SELECT employee_role INTO v_role
    FROM   employee
    WHERE  employee_id = p_approver_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20012, 'Approver not found.');
  END;

  SELECT manager_id INTO v_mgr_id
  FROM   employee
  WHERE  employee_id = v_req.employee_id;

  IF p_approver_id = v_req.employee_id THEN
    RAISE_APPLICATION_ERROR(-20014, 'You cannot approve your own request.');
  END IF;

  IF p_approver_id <> NVL(v_mgr_id, -1) AND v_role <> 'HR' THEN
    RAISE_APPLICATION_ERROR(-20013, 'Only the line manager or HR can approve this request.');
  END IF;

  UPDATE leave_balance
  SET    days_remaining = days_remaining - v_req.days_requested
  WHERE  employee_id   = v_req.employee_id
  AND    leave_type_id = v_req.leave_type_id
  AND    balance_year  = EXTRACT(YEAR FROM v_req.start_date);

  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20015, 'Leave balance record not found.');
  END IF;

  UPDATE leave_request
  SET    status          = 'APPROVED',
         decided_by      = p_approver_id,
         decided_on      = SYSDATE,
         manager_comment = p_comment
  WHERE  request_id = p_request_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_approve_leave;
/

-- Reject a request (a comment is required)

CREATE OR REPLACE PROCEDURE sp_reject_leave (
  p_request_id  IN NUMBER,
  p_approver_id IN NUMBER,
  p_comment     IN VARCHAR2
)
AS
  v_req     leave_request%ROWTYPE;
  v_mgr_id  employee.manager_id%TYPE;
  v_role    employee.employee_role%TYPE;
BEGIN
  IF p_comment IS NULL OR TRIM(p_comment) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20024, 'A comment is required when rejecting a request.');
  END IF;

  BEGIN
    SELECT * INTO v_req
    FROM   leave_request
    WHERE  request_id = p_request_id
    FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20020, 'Leave request not found.');
  END;

  IF v_req.status <> 'PENDING' THEN
    RAISE_APPLICATION_ERROR(-20021, 'Only pending requests can be rejected.');
  END IF;

  BEGIN
    SELECT employee_role INTO v_role
    FROM   employee
    WHERE  employee_id = p_approver_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20022, 'Approver not found.');
  END;

  SELECT manager_id INTO v_mgr_id
  FROM   employee
  WHERE  employee_id = v_req.employee_id;

  IF p_approver_id = v_req.employee_id
     OR (p_approver_id <> NVL(v_mgr_id, -1) AND v_role <> 'HR') THEN
    RAISE_APPLICATION_ERROR(-20023, 'Only the line manager or HR can reject this request.');
  END IF;

  UPDATE leave_request
  SET    status          = 'REJECTED',
         decided_by      = p_approver_id,
         decided_on      = SYSDATE,
         manager_comment = p_comment
  WHERE  request_id = p_request_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_reject_leave;
/

-- Cancel a request
-- Pending: always allowed. Approved: only before it starts,
-- and the days are given back to the balance.

CREATE OR REPLACE PROCEDURE sp_cancel_leave (
  p_request_id  IN NUMBER,
  p_employee_id IN NUMBER
)
AS
  v_req leave_request%ROWTYPE;
BEGIN
  BEGIN
    SELECT * INTO v_req
    FROM   leave_request
    WHERE  request_id = p_request_id
    FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20030, 'Leave request not found.');
  END;

  IF v_req.employee_id <> p_employee_id THEN
    RAISE_APPLICATION_ERROR(-20031, 'You can only cancel your own requests.');
  END IF;

  IF v_req.status = 'PENDING' THEN
    NULL;
  ELSIF v_req.status = 'APPROVED' AND v_req.start_date > TRUNC(SYSDATE) THEN
    UPDATE leave_balance
    SET    days_remaining = days_remaining + v_req.days_requested
    WHERE  employee_id   = v_req.employee_id
    AND    leave_type_id = v_req.leave_type_id
    AND    balance_year  = EXTRACT(YEAR FROM v_req.start_date);
  ELSE
    RAISE_APPLICATION_ERROR(-20032,
      'Only pending requests, or approved requests that have not started, can be cancelled.');
  END IF;

  UPDATE leave_request
  SET    status = 'CANCELLED'
  WHERE  request_id = p_request_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_cancel_leave;
/