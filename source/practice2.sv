/*
    design integern w/ shared integer counter variable. create 2
    concurrent processes that both incrment this counter multiple
    times. use binary semaphore to protect counter and ensure 
    that increments from both processes are atomic and do not 
    lead to race conditions. display final counter value 
*/