%% -------------------------------------------------------------------
%% @author Will Boyce <mail@willboyce.com> [http://willboyce.com]
%% @copyright 2008 Will Boyce
%% @doc Test Event Handler that will crash when someone says ":crash"
%% -------------------------------------------------------------------
-module(erb_handler_crash).
-author("Will Boyce").
-behaviour(gen_event).
-include("erb.hrl").

%% API
-export([start_link/0, add_handler/0]).

%% gen_event callbacks
-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2, code_change/3]).

%% Server macro
-define(SERVER, ?MODULE).

%% State record
-record(state, {}).

%% ===================================================================
%% gen_event callbacks
%% ===================================================================
%% -------------------------------------------------------------------
%% @spec start_link() -> {ok,Pid} | {error,Error}
%% @doc Creates an event manager.
%% -------------------------------------------------------------------
start_link() ->
    gen_event:start_link({local, ?SERVER}).

%% -------------------------------------------------------------------
%% @spec add_handler() -> ok | {'EXIT',Reason} | term()
%% @doc Adds an event handler
%% -------------------------------------------------------------------
add_handler() ->
    gen_event:add_handler(?SERVER, ?MODULE, []).

%% ===================================================================
%% gen_event callbacks
%% ===================================================================
%% -------------------------------------------------------------------
%% @spec init(Args) -> {ok, State}
%% @doc Whenever a new event handler is added to an event manager,
%% this function is called to initialize the event handler.
%% -------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%% -------------------------------------------------------------------
%% @spec
%% handle_event(Event, State) -> {ok, State} |
%%                               {swap_handler, Args1, State1, Mod2, Args2} |
%%                               remove_handler
%% @docWhenever an event manager receives an event sent using
%% gen_event:notify/2 or gen_event:sync_notify/2, this function is called for
%% each installed event handler to handle the event.
%% -------------------------------------------------------------------
handle_event(Data, State) ->
    case Data#data.operation of
        privmsg ->
            case string:equal(Data#data.body, ":crash") of
                true ->
                    1 / 0;
                false ->
                    ok
            end;
        _ ->
            ok
    end,
    {ok, State}.

%% -------------------------------------------------------------------
%% @spec
%% handle_call(Request, State) -> {ok, Reply, State} |
%%                                {swap_handler, Reply, Args1, State1,
%%                                  Mod2, Args2} |
%%                                {remove_handler, Reply}
%% @doc Whenever an event manager receives a request sent using
%% gen_event:call/3,4, this function is called for the specified event
%% handler to handle the request.
%% -------------------------------------------------------------------
handle_call(_Request, State) ->
    Reply = ok,
    {ok, Reply, State}.

%% -------------------------------------------------------------------
%% @spec
%% handle_info(Info, State) -> {ok, State} |
%%                             {swap_handler, Args1, State1, Mod2, Args2} |
%%                              remove_handler
%% @doc This function is called for each installed event handler when
%% an event manager receives any other message than an event or a synchronous
%% request (or a system message).
%% -------------------------------------------------------------------
handle_info(_Info, State) ->
    {ok, State}.

%% -------------------------------------------------------------------
%% @spec terminate(Reason, State) -> void()
%% @docWhenever an event handler is deleted from an event manager,
%% this function is called. It should be the opposite of Module:init/1 and
%% do any necessary cleaning up.
%% -------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% -------------------------------------------------------------------
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @doc Convert process state when code is changed
%% -------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ===================================================================
%% Internal functions
%% ===================================================================
