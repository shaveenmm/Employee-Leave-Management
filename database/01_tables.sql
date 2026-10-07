-- 01_tables.sql
-- Employee Leave Management System
-- Run as the schema owner in SQL Developer 

BEGIN
  FOR t IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name IN ('LEAVE_AUDIT', 'LEAVE_REQUEST', 'LEAVE_BALANCE',
                                  'PUBLIC_HOLIDAY', 'LEAVE_TYPE', 'EMPLOYEE'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/


-- EMPLOYEE

CREATE TABLE employee (
  employee_id    NUMBER GENERATED ALWAYS AS IDENTITY,
  first_name     VARCHAR2(50)  NOT NULL,
  last_name      VARCHAR2(50)  NOT NULL,
  email          VARCHAR2(100) NOT NULL,
  department     VARCHAR2(50)  NOT NULL,
  employee_role  VARCHAR2(10)  DEFAULT 'EMPLOYEE' NOT NULL,
  manager_id     NUMBER,
  hire_date      DATE          DEFAULT SYSDATE NOT NULL,
  is_active      CHAR(1)       DEFAULT 'Y' NOT NULL,
  CONSTRAINT pk_employee         PRIMARY KEY (employee_id),
  CONSTRAINT uq_employee_email   UNIQUE (email),
  CONSTRAINT ck_employee_role    CHECK (employee_role IN ('EMPLOYEE', 'MANAGER', 'HR')),
  CONSTRAINT ck_employee_active  CHECK (is_active IN ('Y', 'N')),
  CONSTRAINT ck_employee_selfmgr CHECK (manager_id IS NULL OR manager_id <> employee_id),
  CONSTRAINT fk_employee_manager FOREIGN KEY (manager_id) REFERENCES employee (employee_id)
);

-- LEAVE_TYPE

CREATE TABLE leave_type (
  leave_type_id  NUMBER GENERATED ALWAYS AS IDENTITY,
  name           VARCHAR2(50)  NOT NULL,
  days_per_year  NUMBER(4,1)   NOT NULL,
  CONSTRAINT pk_leave_type      PRIMARY KEY (leave_type_id),
  CONSTRAINT uq_leave_type_name UNIQUE (name),
  CONSTRAINT ck_leave_type_days CHECK (days_per_year >= 0)
);

-- LEAVE_BALANCE

CREATE TABLE leave_balance (
  employee_id     NUMBER      NOT NULL,
  leave_type_id   NUMBER      NOT NULL,
  balance_year    NUMBER(4)   NOT NULL,
  days_remaining  NUMBER(5,1) NOT NULL,
  CONSTRAINT pk_leave_balance     PRIMARY KEY (employee_id, leave_type_id, balance_year),
  CONSTRAINT fk_balance_employee  FOREIGN KEY (employee_id)   REFERENCES employee (employee_id),
  CONSTRAINT fk_balance_type      FOREIGN KEY (leave_type_id) REFERENCES leave_type (leave_type_id),
  CONSTRAINT ck_balance_nonneg    CHECK (days_remaining >= 0)
);

-- PUBLIC_HOLIDAY

CREATE TABLE public_holiday (
  holiday_date  DATE         NOT NULL,
  name          VARCHAR2(80) NOT NULL,
  CONSTRAINT pk_public_holiday PRIMARY KEY (holiday_date)
);

-- LEAVE_REQUEST

CREATE TABLE leave_request (
  request_id       NUMBER GENERATED ALWAYS AS IDENTITY,
  employee_id      NUMBER        NOT NULL,
  leave_type_id    NUMBER        NOT NULL,
  start_date       DATE          NOT NULL,
  end_date         DATE          NOT NULL,
  days_requested   NUMBER(4,1)   NOT NULL,
  reason           VARCHAR2(250),
  status           VARCHAR2(10)  DEFAULT 'PENDING' NOT NULL,
  manager_comment  VARCHAR2(250),
  date_submitted   DATE          DEFAULT SYSDATE NOT NULL,
  decided_by       NUMBER,
  decided_on       DATE,
  CONSTRAINT pk_leave_request    PRIMARY KEY (request_id),
  CONSTRAINT fk_request_employee FOREIGN KEY (employee_id)   REFERENCES employee (employee_id),
  CONSTRAINT fk_request_type     FOREIGN KEY (leave_type_id) REFERENCES leave_type (leave_type_id),
  CONSTRAINT fk_request_decider  FOREIGN KEY (decided_by)    REFERENCES employee (employee_id),
  CONSTRAINT ck_request_dates    CHECK (end_date >= start_date),
  CONSTRAINT ck_request_days     CHECK (days_requested > 0),
  CONSTRAINT ck_request_status   CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'))
);

CREATE INDEX idx_request_employee ON leave_request (employee_id, start_date);
CREATE INDEX idx_request_status   ON leave_request (status);

-- LEAVE_AUDIT

CREATE TABLE leave_audit (
  audit_id    NUMBER GENERATED ALWAYS AS IDENTITY,
  request_id  NUMBER       NOT NULL,
  old_status  VARCHAR2(10),
  new_status  VARCHAR2(10) NOT NULL,
  changed_by  VARCHAR2(50) DEFAULT USER NOT NULL,
  changed_on  TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
  CONSTRAINT pk_leave_audit   PRIMARY KEY (audit_id),
  CONSTRAINT fk_audit_request FOREIGN KEY (request_id) REFERENCES leave_request (request_id)
);