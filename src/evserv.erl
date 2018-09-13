-module(evserv).

-record(state, {
    events,
    clients
}).

-record(event, {
    name="",
    description="",
    pid,
    timeout={{1970,1,1}, {0,0,0}}
}).



loop(S = #state{}) ->
    receive
        {Pid, MsgRef, {subscribe, Client}} ->
            Ref = erlang:monitor(process,Client),
            NewClients = orddict:store(Ref, Client, S#state.clients),
            Pid ! {MsgRef, ok},
            loop(S#state{clients=NewClients});
        {Pid, MsgRef, {add, Name, Description, TimeOut}} ->
            ok;
        {Pid, MsgRef, {cancel, Name}} -> 
            ok;
        {done, Name} ->
            ok;
        shutdown ->
            ok;
        {'DOWN', Ref, process, _Pid, _Reason} ->
            ok;
        code_change ->
            ok;
        Unknown -> 
            io:format("Unknown message: ~p ~n", [Unknown]),
            loop(S)
    end.

init() -> 
    loop(#state{events=orddict:new(),
                clients=orddict:new()}).

valid_datetime({Date,Time}) ->
    try
        calendar:valid_date(Date) andalso valid_time(Time)
    catch
        error:function_clause -> %% not in {{D,M,Y},{H,Min,S}} format
        false
    end;
valid_datetime(_) ->
    false.
valid_time({H,M,S}) -> 
    valid_time(H,M,S).
valid_time(H,M,S) 
       when H >= 0, H < 24,
            M >= 0, M < 60,
            S >= 0, S < 60 -> true;
            valid_time(_,_,_) -> false.
