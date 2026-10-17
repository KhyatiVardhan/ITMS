String jobName = 'Case SLA Breach Daily';
String cronExpression = '0 0 2 * * ?';

System.schedule(
    jobName,
    cronExpression,
    new CaseSlaBreachScheduler()
);