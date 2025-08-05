-- Table 1: Job Department
create database MyProject;
use MyProject;
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);
select * from JobDepartment;
-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
select * from SalaryBonus;
-- Table 3: Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
        REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
select * from Employee;


-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
        REFERENCES Employee(emp_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
select * from Qualification;

-- Table 5: Leaves
CREATE TABLE `Leaves` (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
select * from `Leaves`;


-- Table 6: Payroll
CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);
select * from Payroll;

select * from JobDepartment;
select * from SalaryBonus;
select * from Employee;
select * from Qualification;
select * from `Leaves`;
select * from Payroll;

-- 1. EMPLOYEE INSIGHTS
/* How many unique employees are currently in the system? */
select count(*) as no_unique_values from (select emp_ID from Employee
			group by emp_ID) as emp_unique; -- 60 employees

select count(*) as no_unique_employees from (select distinct emp_ID from Employee) 
						as emp_unique;  -- 60 employees

/* Which departments have the highest number of employees? */
with cte_1 as (select *,dense_rank() over(order by Freq desc) as `dense_rank` 
		from (select jobdept,count(*) as Freq from JobDepartment
		left join Employee
        using(Job_ID)
        group by jobdept) as s)
        select jobdept from cte_1
				where `dense_rank` = 1;   -- Finance, IT

/* What is the average salary per department? */


with cte_1 as (select *,cast(replace(substring_index(salaryrange,'-',1),'$','') as unsigned) as start_sal,
		cast(replace(substring_index(salaryrange,'-',-1),'$','') as unsigned) as end_sal 
        from JobDepartment)
        select jobdept,avg(end_sal) as Avg_salary from cte_1
				group by jobdept;
                
                
/* Who are the top 5 highest-paid employees? */

with cte_1 as (select *,annual+bonus as total_sal from Employee
		left join JobDepartment
        using(Job_ID)
        left join SalaryBonus
        using(Job_ID)
        order by total_sal desc
        limit 5)
select emp_ID,concat(firstname,' ',lastname) as Employees from cte_1;

/* What is the total salary expenditure across the company? */

select jobdept,sum(annual)+sum(bonus) as total_expenditure from JobDepartment
		left join SalaryBonus
        using(Job_ID)
        group by jobdept;
        
-- 2. JOB ROLE AND DEPARTMENT ANALYSIS
/* How many different job roles exist in each department? */

select jobdept,count(distinct `name`) as No_of_jobs from JobDepartment
		group by jobdept;
        
/* What is the average salary range per department? */

select * from JobDepartment;
with cte_1 as (select *,cast(replace(substring_index(salaryrange,'-',1),'$','') as unsigned) as start_sal,
		cast(replace(substring_index(salaryrange,'-',-1),'$','') as unsigned) as end_sal 
        from JobDepartment),
        
cte_2 as (select jobdept,round((sum(start_sal)+sum(end_sal))/2,2) as Avg_salary 
			from cte_1
            group by jobdept)
select * from cte_2;

/* Which job roles offer the highest salary? */

with cte_1 as (select *,cast(replace(substring_index(salaryrange,'-',-1),'$','') as unsigned) as highest_sal 
        from JobDepartment)
select `name`,highest_sal from cte_1
        order by highest_sal desc
        limit 3;
        
/* Which departments have the highest total salary allocation? */
select * from JobDepartment;
select * from SalaryBonus;

with cte_1 as (select *,annual+bonus as total_sal from JobDepartment
		left join SalaryBonus
        using(Job_ID))
select jobdept,sum(total_sal) as total_sal from cte_1
		group by jobdept
        order by total_sal desc;

-- 3. QUALIFICATION AND SKILLS ANALYSIS
/* How many employees have at least one qualification listed? */

select * from Qualification;
with cte_1 as (select * from Employee
		left join Qualification
        using(Emp_ID)),
cte_2 as (select emp_ID,firstname,lastname,count(Requirements) as No_of_qualif
			from cte_1
            group by emp_ID,firstname,lastname)
		select count(*) as no_of_emp from cte_2; -- 60 employees
        
        
/* Which positions require the most qualifications? */
select * from Qualification;
select Position,count(*) from Qualification
			group by Position;

/* Which employees have the highest number of qualifications? */
select * from Employee
		left join Qualification
        using(Emp_ID);


-- 4. LEAVE AND ABSENCE PATTERNS
/* Which year had the most employees taking leaves? */
select * from `Leaves`;
select year(`date`) as `year`,count(emp_ID) as cnt from `Leaves`
		group by year(`date`)
        order by cnt desc;
        
/* What is the average number of leave days taken by its employees per department? */ 
select * from `Leaves`;       
with cte_1 as (select *,count(leave_ID) as leave_days from JobDepartment
		left join Employee
        using(Job_ID)
        inner join `Leaves`
        using(emp_ID)
        group by leave_ID)
select jobdept,round(avg(leave_days)) as avg_leaves from cte_1
			group by jobdept;
            
/* Which employees have taken the most leaves? */
with cte_1 as (select * from Employee
		left join `Leaves`
        using(emp_ID))
select emp_ID,firstname,lastname,count(leave_ID) as leave_days from cte_1
			group by emp_ID,firstname,lastname,leave_ID
            order by leave_days desc;
       
/* What is the total number of leave days taken company-wide? */
select * from `Leaves`;
select * from JobDepartment;

with cte_1 as (select * from JobDepartment
		left join Employee
        using(Job_ID)
        left join `Leaves`
        using(emp_ID))
select jobdept,count(leave_ID) as leave_cnt from cte_1
		group by jobdept;
        
/* How do leave days correlate with payroll amounts? */
select * from `Leaves`
		where exists (select * from Payroll
					where `Leaves`.leave_ID = Payroll.leave_ID);
/* Explanation :
	Based on the common column 'leave_ID' the leave days are correlated with
    'payroll' amounts. Due to this 'leave_ID' the payroll of every month will
    be decided for the employees. */

-- 5. PAYROLL AND COMPENSATION ANALYSIS
/* What is the total monthly payroll processed? */
select * from Payroll;
select monthname(`date`) as month_,sum(total_amount) as month_total_payroll from Payroll
		group by monthname(`date`);

/* What is the average bonus given per department? */

with cte_1 as (select * from JobDepartment
		left join SalaryBonus
        using(Job_ID))
select jobdept,round(avg(bonus),2) as avg_bonus from cte_1
			group by jobdept;
            
/* Which department receives the highest total bonuses? */

with cte_1 as (select * from JobDepartment
		left join SalaryBonus
        using(Job_ID))
select jobdept,sum(bonus) as total_bonus from cte_1
		group by jobdept
        order by total_bonus desc
        limit 1;  -- Finance
        
/* What is the average value of total_amount after considering leave deductions? */

select * from Payroll;
select * from `Leaves`;

select avg(total_amount) as avg_total_amount from Payroll;-- '46300.000000'

select * from SalaryBonus;
select * from JobDepartment;
select * from Employee;
select * from Qualification;

-- 6. EMPLOYEE PERFORMANCE AND GROWTH
/* Which year had the highest number of employee promotions? */
with cte_1 as (select * from Employee
		left join Qualification
        using(Emp_ID)
		left join SalaryBonus
        using(Job_ID)) 
select year(Date_In) as `year`,count(*) as no_of_promotions from cte_1
			group by year(Date_In)
            order by no_of_promotions desc
            limit 1;
		-- group by Position;
			-- order by annual desc;
       