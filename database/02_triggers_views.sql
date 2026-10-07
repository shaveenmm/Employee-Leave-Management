-- 02_triggers_views.sql
-- Audit trigger and reporting views
-- Run after 01_tables.sql

-- Audit trigger: logs every new request and every status change

CREATE OR REPLACE TRIGGER trg_leave_request_audit
AFTER INSERT OR UPDATE OF status ON leave_request
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    INSERT INTO leave_audit (request_id, old_status, new_status)
    VALUES (:NEW.request_id, NULL, :NEW.status);
  ELSIF :OLD.status <> :NEW.status THEN
    INSERT INTO leave_audit (request_id, old_status, new_status)
    VALUES (:NEW.request_id, :OLD.status, :NEW.status);
  END IF;
END;
/

-- Requests waiting for a decision (manager dashboard)

CREATE OR REPLACE VIEW vw_pending_requests AS
SELECT r.request_id,
       e.employee_id,
       e.first_name || ' ' || e.last_name AS employee_name,
       e.department,
       e.manager_id,
       lt.name                            AS leave_type,
       r.start_date,
       r.end_date,
       r.days_requested,
       r.reason,
       r.date_submitted
FROM   leave_request r
JOIN   employee   e  ON e.employee_id    = r.employee_id
JOIN   leave_type lt ON lt.leave_type_id = r.leave_type_id
WHERE  r.status = 'PENDING';

-- Who is off and when (team calendar)

CREATE OR REPLACE VIEW vw_team_calendar AS
SELECT r.request_id,
       e.first_name || ' ' || e.last_name AS employee_name,
       e.department,
       e.manager_id,
       lt.name                            AS leave_type,
       r.start_date,
       r.end_date,
       r.days_requested
FROM   leave_request r
JOIN   employee   e  ON e.employee_id    = r.employee_id
JOIN   leave_type lt ON lt.leave_type_id = r.leave_type_id
WHERE  r.status = 'APPROVED';

-- Approved leave per department and leave type (HR report)

CREATE OR REPLACE VIEW vw_leave_summary AS
SELECT e.department,
       lt.name              AS leave_type,
       COUNT(*)             AS approved_requests,
       SUM(r.days_requested) AS total_days
FROM   leave_request r
JOIN   employee   e  ON e.employee_id    = r.employee_id
JOIN   leave_type lt ON lt.leave_type_id = r.leave_type_id
WHERE  r.status = 'APPROVED'
GROUP BY e.department, lt.name;