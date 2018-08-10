global class CCDisableHeWUserScheduler implements Schedulable {
	global CCDisableHeWUserScheduler() {}
	global void execute(SchedulableContext ctx) {
		CCDisableHeWUserBatch batchjob = new CCDisableHeWUserBatch();
		ID batchId = Database.executeBatch(batchjob,200);
	}
}