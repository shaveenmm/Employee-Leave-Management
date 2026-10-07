-- 04_seed_data.sql
-- Demo data so the app looks alive in screenshots
-- Run after 03_procedures.sql

-- Leave types (simplified entitlements for the demo)
INSERT INTO leave_type (name, days_per_year) VALUES ('Annual Leave', 21);
INSERT INTO leave_type (name, days_per_year) VALUES ('Sick Leave', 10);
INSERT INTO leave_type (name, days_per_year) VALUES ('Family Responsibility Leave', 3);
INSERT INTO leave_type (name, days_per_year) VALUES ('Study Leave', 5);

-- Public holidays 2026 (South Africa)
-- Please verify against the official government list before
-- relying on these. Women's Day (9 Aug) falls on a Sunday in 2026,
-- so the Monday is observed.

INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-01-01', 'New Year''s Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-03-21', 'Human Rights Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-04-03', 'Good Friday');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-04-06', 'Family Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-04-27', 'Freedom Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-05-01', 'Workers'' Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-06-16', 'Youth Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-08-10', 'Public Holiday (Women''s Day observed)');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-09-24', 'Heritage Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-12-16', 'Day of Reconciliation');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-12-25', 'Christmas Day');
INSERT INTO public_holiday (holiday_date, name) VALUES (DATE '2026-12-26', 'Day of Goodwill');

-- Employees: HR first, then managers, then staff

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Shaveen', 'Moodley', 'shaveen.moodley@company.co.za', 'Human Resources', 'HR', NULL, DATE '2019-02-01');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Pete', 'Davids', 'pete.davids@company.co.za', 'IT', 'MANAGER', NULL, DATE '2020-06-15');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Dylan', 'Stone', 'dylan.stone@company.co.za', 'Finance', 'MANAGER', NULL, DATE '2018-09-03');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Juan', 'Martinez', 'juan.martinez@company.co.za', 'IT', 'EMPLOYEE',
        (SELECT employee_id FROM employee WHERE email = 'pete.davids@company.co.za'), DATE '2022-03-14');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Liam', 'van der Merwe', 'liam.vandermerwe@company.co.za', 'IT', 'EMPLOYEE',
        (SELECT employee_id FROM employee WHERE email = 'pete.davids@company.co.za'), DATE '2021-08-02');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Mvelo', 'Khumalo', 'mvelo.khumalo@company.co.za', 'IT', 'EMPLOYEE',
        (SELECT employee_id FROM employee WHERE email = 'pete.davids@company.co.za'), DATE '2023-01-23');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Kyle', 'Pillay', 'kyle.pillay@company.co.za', 'Finance', 'EMPLOYEE',
        (SELECT employee_id FROM employee WHERE email = 'dylan.stone@company.co.za'), DATE '2022-11-07');

INSERT INTO employee (first_name, last_name, email, department, employee_role, manager_id, hire_date)
VALUES ('Zanele', 'Mthembu', 'zanele.mthembu@company.co.za', 'Finance', 'EMPLOYEE',
        (SELECT employee_id FROM employee WHERE email = 'dylan.stone@company.co.za'), DATE '2024-02-12');

-- 2026 balances: every employee gets every leave type

INSERT INTO leave_balance (employee_id, leave_type_id, balance_year, days_remaining)
SELECT e.employee_id, lt.leave_type_id, 2026, lt.days_per_year
FROM   employee e
CROSS JOIN leave_type lt;

COMMIT;

-- Sample requests, created through the stored procedures so the
-- business rules and the audit trigger are exercised

DECLARE
  v_id NUMBER;

  FUNCTION emp (p_email VARCHAR2) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT employee_id INTO v FROM employee WHERE email = p_email;
    RETURN v;
  END;

  FUNCTION ltype (p_name VARCHAR2) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT leave_type_id INTO v FROM leave_type WHERE name = p_name;
    RETURN v;
  END;
BEGIN
  -- Pending
  sp_submit_leave(emp('juan.martinez@company.co.za'), ltype('Annual Leave'),
                  DATE '2026-11-02', DATE '2026-11-06', 'Family holiday', v_id);

  -- Approved (16 Dec is a public holiday, so this counts as 4 days)
  sp_submit_leave(emp('liam.vandermerwe@company.co.za'), ltype('Annual Leave'),
                  DATE '2026-12-14', DATE '2026-12-18', 'Year-end break', v_id);
  sp_approve_leave(v_id, emp('pete.davids@company.co.za'), 'Enjoy the break.');

  -- Rejected
  sp_submit_leave(emp('kyle.pillay@company.co.za'), ltype('Annual Leave'),
                  DATE '2026-11-23', DATE '2026-11-27', 'Personal errands', v_id);
  sp_reject_leave(v_id, emp('dylan.stone@company.co.za'),
                  'Month-end close, please pick another week.');

  -- Approved sick leave
  sp_submit_leave(emp('zanele.mthembu@company.co.za'), ltype('Sick Leave'),
                  DATE '2026-10-12', DATE '2026-10-13', 'Flu', v_id);
  sp_approve_leave(v_id, emp('dylan.stone@company.co.za'), 'Get well soon.');
END;
/