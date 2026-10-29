-- Experiment 6
-- Aim: Stored procedure transfer_employee(emp_id, new_dept_id), validation,
-- triggers for salary validation and audit logging, and edge-case testing.
-- Prerequisite: Run Experiment-4.sql first so Employee.manager_id exists.
-- MySQL syntax: DELIMITER must be followed by a delimiter token such as $$.

CREATE TABLE audit_log (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  emp_id INT,
  action_type VARCHAR(20),
  old_value VARCHAR(100),
  new_value VARCHAR(100),
  changed_on DATETIME DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_salary_check_insert;
DROP TRIGGER IF EXISTS trg_salary_check_update;

DELIMITER $$
CREATE TRIGGER trg_salary_check_insert
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
  IF NEW.salary IS NULL OR NEW.salary < 10000 OR NEW.salary > 200000 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid salary: must be between 10000 and 200000';
  END IF;
END$$

CREATE TRIGGER trg_salary_check_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
  IF NEW.salary IS NULL OR NEW.salary < 10000 OR NEW.salary > 200000 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid salary: must be between 10000 and 200000';
  END IF;
  IF NEW.salary < OLD.salary * 0.5 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Salary cannot be reduced by more than 50 percent';
  END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_audit_insert;
DROP TRIGGER IF EXISTS trg_audit_update;
DROP TRIGGER IF EXISTS trg_audit_delete;

DELIMITER $$
CREATE TRIGGER trg_audit_insert
AFTER INSERT ON Employee
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (emp_id, action_type, old_value, new_value)
  VALUES (NEW.emp_id, 'INSERT', NULL,
          CONCAT(NEW.emp_name, ' | dept ', NEW.dept_id));
END$$

CREATE TRIGGER trg_audit_update
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
  IF NOT (OLD.salary <=> NEW.salary) THEN
    INSERT INTO audit_log (emp_id, action_type, old_value, new_value)
    VALUES (NEW.emp_id, 'SALARY_CHANGE', OLD.salary, NEW.salary);
  END IF;
  IF NOT (OLD.dept_id <=> NEW.dept_id) THEN
    INSERT INTO audit_log (emp_id, action_type, old_value, new_value)
    VALUES (NEW.emp_id, 'DEPT_TRANSFER', OLD.dept_id, NEW.dept_id);
  END IF;
END$$

CREATE TRIGGER trg_audit_delete
AFTER DELETE ON Employee
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (emp_id, action_type, old_value, new_value)
  VALUES (OLD.emp_id, 'DELETE',
          CONCAT(OLD.emp_name, ' | dept ', OLD.dept_id), NULL);
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS transfer_employee;

DELIMITER $$
CREATE PROCEDURE transfer_employee(IN p_emp_id INT, IN p_new_dept_id INT)
BEGIN
  DECLARE v_count INT DEFAULT 0;
  DECLARE v_old_dept INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  IF p_emp_id IS NULL OR p_new_dept_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Employee id and department id cannot be NULL';
  END IF;

  SELECT COUNT(*) INTO v_count FROM Employee WHERE emp_id = p_emp_id;
  IF v_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Employee does not exist';
  END IF;

  SELECT COUNT(*) INTO v_count FROM Department WHERE dept_id = p_new_dept_id;
  IF v_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Target department does not exist';
  END IF;

  SELECT dept_id INTO v_old_dept FROM Employee WHERE emp_id = p_emp_id;
  IF v_old_dept = p_new_dept_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Employee is already in this department';
  END IF;

  SELECT COUNT(*) INTO v_count FROM Employee WHERE manager_id = p_emp_id;
  IF v_count > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cannot transfer an employee who manages other employees';
  END IF;

  UPDATE Employee SET dept_id = p_new_dept_id WHERE emp_id = p_emp_id;
  COMMIT;

  SELECT CONCAT('Employee ', p_emp_id, ' transferred from dept ',
                v_old_dept, ' to dept ', p_new_dept_id) AS message;
END$$
DELIMITER ;

-- Example call (choose an employee who does not manage other employees):
-- CALL transfer_employee(128, 2);
-- Inspect audit entries:
-- SELECT * FROM audit_log ORDER BY changed_on DESC;
