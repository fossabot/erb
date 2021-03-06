%% -------------------------------------------------------------------
%% @author Will Boyce <me@willboyce.com> [http://willboyce.com]
%% @copyright 2011 Will Boyce
%% @doc Manages multiple bot configurations
%% -------------------------------------------------------------------
-module(erb_bot_manager).
-behaviour(gen_server).
-include("erb.hrl").

%% API
-export([start_link/0, gen_spec/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% Server macro
-define(SERVER, ?MODULE).

%% State record
-record(state, {bots=[]}).

%% ===================================================================
%% API
%% ===================================================================

%% -------------------------------------------------------------------
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @doc Starts the server
%% -------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%% ===================================================================
%% gen_server callbacks
%% ===================================================================
%% -------------------------------------------------------------------
%% @spec init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% @doc Initiates the server
%% -------------------------------------------------------------------
init([]) ->
    Bots = case gen_server:call({global, erb_config_server}, getBots) of
        {ok, Config} ->
            Config;
        _ ->
            []
    end,
    lists:map(fun(Bot) ->
        gen_server:cast(self(), {startBot, Bot})
    end, Bots),
    {ok, #state{}}.

%% -------------------------------------------------------------------
%% @spec handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% @doc Handling call messages
%% -------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    {ok, State}.

%% -------------------------------------------------------------------
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% @doc Handling cast messages
%% -------------------------------------------------------------------
%% @doc add a new bot to the database/state and start it
handle_cast({addBot, Nick, Network, Chans}, State) ->
    BotSpec = {Nick, Network, Chans},
    {ok, NewBot} = gen_server:call({global, erb_config_server}, {addBot, BotSpec}),
    ok = start_bot(NewBot),
    {noreply, State#state{ bots=[State#state.bots|NewBot] }};
%% @doc starts a bot, which should already exist inside the State
handle_cast({startBot, Bot}, State) ->
    ok = start_bot(Bot),
    {noreply, State};
handle_cast({stopBot, Bot}, State) ->
    ok = stop_bot(Bot),
    {noreply, State};
handle_cast({removeBot, Bot}, State) ->
    ok = gen_server:call({global, erb_config_server}, {removeBot, Bot#bot.id}),
    ok = stop_bot(Bot),
    {noreply, State};
handle_cast(_Request, State) ->
    {noreply, State}.

%% -------------------------------------------------------------------
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% @doc Handling all non call/cast messages
%% -------------------------------------------------------------------
handle_info(_Reqest, State) ->
    {noreply, State}.

%% -------------------------------------------------------------------
%% @spec terminate(Reason, State) -> ok
%% @doc This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
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
gen_spec(Bot) ->
    {Bot#bot.id,
            {erb_bot_supervisor, start_link, [Bot]},
            permanent,
            infinity,
            supervisor,
            [erb_bot_supervisor]}.

start_bot(Bot) ->
    ChildSpec = gen_spec(Bot),
    supervisor:start_child({global, erb_supervisor}, ChildSpec),
    ok.

stop_bot(Bot) ->
    supervisor:stop_child({global, erb_supervisor}, Bot#bot.id),
    supervisor:delete_child({global, erb_supervisor}, Bot#bot.id),
    ok.
