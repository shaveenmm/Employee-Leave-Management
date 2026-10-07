-- 05_test_queries.sql
-- Quick checks that the schema and business rules work
-- Run each section on its own in SQL Developer

SET SERVEROUTPUT ON;

-- 1. Working days: 14 to 18 Dec 2026 should return 4 (16 Dec is a holiday)
SELECT fn_working_days(DATE '2026-12-14', DATE '2026-12-18') AS working_days
FROM   dual;

-- 2. Pending requests (should show Juan's November request)
SELECT * FROM vw_pending_requests;

-- 3. Team calendar (approved leave only)
SELECT * FROM vw_team_calendar ORDER BY start_date;

-- 4. Department report
SELECT * FROM vw_leave_summary ORDER BY department, leave_type;

-- 5. Audit trail: every submit, approve and reject should appear
SELECT a.audit_id, a.request_id, a.old_status, a.new_status, a.changed_on
FROM   leave_audit a
ORDER BY a.audit_id;

-- 6. Balances after approvals (Liam annual should be 17, Zanele sick should be 8)
SELECT e.first_name, lt.name AS leave_type, b.days_remaining
FROM   leave_balance b
JOIN   employee   e  ON e.employee_id    = b.employee_id
JOIN   leave_type lt ON lt.leave_type_id = b.leave_type_id
WHERE  e.email IN ('liam.vandermerwe@company.co.za', 'zanele.mthembu@company.co.za')
AND    lt.name IN ('Annual Leave', 'Sick Leave')
ORDER BY e.first_name, lt.name;

-- Negative tests: each block should print the expected error

-- 7. Overlap: Juan already has pending leave 2 to 6 Nov (expect -20004)
DECLARE
  v_id NUMBER;
BEGIN
  sp_submit_leave(
    (SELECT employee_id FROM employee WHERE email = 'juan.martinez@company.co.za'),
    (SELECT leave_type_id FROM leave_type WHERE name = 'Annual Leave'),
    DATE '2026-11-04', DATE '2026-11-05', 'Overlap test', v_id);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- 8. Too many days: 30 working days of study leave (expect -20006)
DECLARE
  v_id NUMBER;
BEGIN
  sp_submit_leave(
    (SELECT employee_id FROM employee WHERE email = 'mvelo.khumalo@company.co.za'),
    (SELECT leave_type_id FROM leave_type WHERE name = 'Study Leave'),
    DATE '2026-02-02', DATE '2026-03-13', 'Balance test', v_id);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- 9. Wrong approver: Dylan manages Finance, not Juan in IT (expect -20013)
DECLARE
  v_req NUMBER;
BEGIN
  SELECT request_id INTO v_req
  FROM   vw_pending_requests
  WHERE  employee_name = 'Juan Martinez';

  sp_approve_leave(
    v_req,
    (SELECT employee_id FROM employee WHERE email = 'dylan.stone@company.co.za'),
    'Should not work');
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- 10. Weekend only: Saturday and Sunday (expect -20003)
DECLARE
  v_id NUMBER;
BEGIN
  sp_submit_leave(
    (SELECT employee_id FROM employee WHERE email = 'mvelo.khumalo@company.co.za'),
    (SELECT leave_type_id FROM leave_type WHERE name = 'Annual Leave'),
    DATE '2026-10-17', DATE '2026-10-18', 'Weekend test', v_id);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/