trigger ClosedOpportunityTrigger on Opportunity (after insert, after update) {
    List<Task> taskList = new List<Task>();

    for(Opportunity op : Trigger.new){
        if(op.StageName == 'Closed Won'){
            Task t = new Task(
            Subject = 'Follow Up Test Task',
            WhatId = op.Id      
            );
            taskList.add(t);
    }
    }
    if(!taskList.isEmpty()){
        insert taskList;
    }
}