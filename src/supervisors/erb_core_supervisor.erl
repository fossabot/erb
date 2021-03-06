%% -------------------------------------------------------------------
%% @author Will Boyce <mail@willboyce.com> [http://willboyce.com]
%% @copyright 2008 Will Boyce
%% @doc Supervisor for the core processes
%% -------------------------------------------------------------------
-module(erb_core_supervisor).
-author("Will Boyce").
-include("erb.hrl").

-behaviour(supervisor).

%% API
-export([start_link/1]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================
%% -------------------------------------------------------------------
%% @spec start_link() -> {ok,Pid} | ignore | {error,Error}
%% @doc Starts the supervisor
%% -------------------------------------------------------------------
start_link(Bot) ->
    ProcName = list_to_atom("erb_core_supervisor_" ++ atom_to_list(Bot#bot.id)),
    supervisor:start_link({local, ProcName}, ?MODULE, [Bot]).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================
%% -------------------------------------------------------------------
%% @spec init(Args) -> {ok,  {SupFlags,  [ChildSpec]}} |
%%                     ignore                          |
%%                     {error, Reason}
%% @doc Whenever a supervisor is started using
%% supervisor:start_link/[2,3], this function is called by the new process
%% to find out about restart strategy, maximum restart frequency and child
%% specifications.
%% -------------------------------------------------------------------
init([Bot]) ->
        ProcessorId = {global, list_to_atom("erb_processor_" ++ atom_to_list(Bot#bot.id))},
        ConnectorId = {global, list_to_atom("erb_connector_" ++ atom_to_list(Bot#bot.id))},
	Router			= {erb_router,
                                                {erb_router, start_link, [Bot]},
						permanent,
						2000,
						worker,
						[erb_router]},
	Dispatcher		= {erb_dispatcher,
                                                {erb_dispatcher, start_link, [Bot, ConnectorId]},
						permanent,
						2000,
						worker,
						[erb_dispatcher]},
	Processor		= {erb_processor,
						{erb_processor, start_link, [Bot, ProcessorId]},
						permanent,
						2000,
						worker,
						[erb_processor]},
	Connector		= {erb_connector,
						{erb_connector, start_link, [Bot, ConnectorId, ProcessorId]},
						permanent,
						2000,
						worker,
						[erb_connector]},
    {ok, {{one_for_all, 5, 60}, [Router, Dispatcher, Processor, Connector]}}.

%% ===================================================================
%% Internal functions
%% ===================================================================
