--Login as SYS to 12c database

set echo     off
set feedback off
set pagesize 0

spool create_profiles_in_12.1.0.2_database.log

SELECT 'Script Run-Time Environment:'                   || CHR(10) ||    
'Server  : ' || sys_context('USERENV', 'SERVER_HOST')   || CHR(10) ||       
'Instance: ' || sys_context('USERENV', 'INSTANCE_NAME') || CHR(10) ||      
'Database: ' || sys_context('USERENV', 'DB_NAME')       || CHR(10) ||               
'Username: ' || sys_context('USERENV', 'SESSION_USER')  || CHR(10) ||               
'Time    : ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS')
FROM dual;

set feedback on
set echo on

-------------------------------------------------------------------------------------------------
--Create password verify function

create or replace function celgene_ora12c_verify_function
(username varchar2,
 password varchar2,
 old_password varchar2)
return boolean IS
   differ integer;
begin
   if not ora_complexity_check(password, chars => 8, upper => 1, lower => 1,
                           digit => 1, special => 1) then
      return(false);
   end if;

   -- Check if the password differs from the previous password by at least
   -- 4 characters
   if old_password is not null then
      differ := ora_string_distance(old_password, password);
      if differ < 4 then
         raise_application_error(-20032, 'Password should differ from previous '
                                 || 'password by at least 4 characters');
      end if;
   end if;

   return(true);
end;
/

show errors

GRANT EXECUTE ON celgene_ora12c_verify_function TO PUBLIC;

-------------------------------------------------------------------------------------------------
--Create profiles

CREATE PROFILE SYSTEM
  LIMIT 
  COMPOSITE_LIMIT           UNLIMITED 
  SESSIONS_PER_USER         UNLIMITED 
  CPU_PER_SESSION           UNLIMITED 
  CPU_PER_CALL              UNLIMITED 
  LOGICAL_READS_PER_SESSION UNLIMITED 
  LOGICAL_READS_PER_CALL    UNLIMITED 
  IDLE_TIME                 UNLIMITED 
  CONNECT_TIME              UNLIMITED 
  PRIVATE_SGA               UNLIMITED 
  FAILED_LOGIN_ATTEMPTS     3
  PASSWORD_LOCK_TIME        1
  PASSWORD_LIFE_TIME        90
  PASSWORD_GRACE_TIME       7
  PASSWORD_REUSE_MAX        5
  PASSWORD_REUSE_TIME       365
  PASSWORD_VERIFY_FUNCTION  celgene_ora12c_verify_function;

CREATE PROFILE USERS
  LIMIT 
  COMPOSITE_LIMIT           UNLIMITED 
  SESSIONS_PER_USER         UNLIMITED 
  CPU_PER_SESSION           UNLIMITED 
  CPU_PER_CALL              UNLIMITED 
  LOGICAL_READS_PER_SESSION UNLIMITED 
  LOGICAL_READS_PER_CALL    UNLIMITED 
  IDLE_TIME                 UNLIMITED 
  CONNECT_TIME              UNLIMITED 
  PRIVATE_SGA               UNLIMITED 
  FAILED_LOGIN_ATTEMPTS     3
  PASSWORD_LOCK_TIME        1
  PASSWORD_LIFE_TIME        90
  PASSWORD_GRACE_TIME       7
  PASSWORD_REUSE_MAX        5
  PASSWORD_REUSE_TIME       365
  PASSWORD_VERIFY_FUNCTION  celgene_ora12c_verify_function;

CREATE PROFILE SERVICE
  LIMIT 
  COMPOSITE_LIMIT           UNLIMITED 
  SESSIONS_PER_USER         UNLIMITED 
  CPU_PER_SESSION           UNLIMITED 
  CPU_PER_CALL              UNLIMITED 
  LOGICAL_READS_PER_SESSION UNLIMITED 
  LOGICAL_READS_PER_CALL    UNLIMITED 
  IDLE_TIME                 UNLIMITED 
  CONNECT_TIME              UNLIMITED 
  PRIVATE_SGA               UNLIMITED 
  FAILED_LOGIN_ATTEMPTS     UNLIMITED
  PASSWORD_LOCK_TIME        UNLIMITED
  PASSWORD_LIFE_TIME        UNLIMITED
  PASSWORD_GRACE_TIME       UNLIMITED
  PASSWORD_REUSE_MAX        5
  PASSWORD_REUSE_TIME       365
  PASSWORD_VERIFY_FUNCTION  celgene_ora12c_verify_function;

-------------------------------------------------------------------------------------------------
--Assign profiles to SYS, SYSTEM and DBSNMP accounts

ALTER USER sys    PROFILE SYSTEM;
ALTER USER system PROFILE SYSTEM;
ALTER USER dbsnmp PROFILE SERVICE;

-------------------------------------------------------------------------------------------------

spool off
