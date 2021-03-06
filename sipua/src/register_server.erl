%%%
%%% @doc       SIP REGISTER manager server
%%% @author    Mikael Magnusson <mikma@users.sourceforge.net>
%%% @copyright 2006 Mikael Magnusson
%%%
-module(register_server).

-behaviour(gen_server).

-include("siprecords.hrl").

%% api
-export([
	 start_link/0,
	 stop/0,
	 register_aor/1,
	 unregister_aor/1
	]).

%% gen_server callbacks
-export([init/1,
	 code_change/3,
	 handle_call/3,
	 handle_cast/2,
	 handle_info/2,
	 terminate/2]).

-record(state, {
	 }).

-define(SERVER, ?MODULE).


%%--------------------------------------------------------------------
%% @spec start_link() -> {ok, Pid}
%% @doc Start client register server process
%% @end
%%--------------------------------------------------------------------
start_link() ->
    {ok, Pid} = gen_server:start_link({local, ?SERVER}, ?MODULE, [], []),
    {ok, Pid}.


%%--------------------------------------------------------------------
%% @spec stop() -> ok
%% @doc Stop server process
%% @end
%%--------------------------------------------------------------------
stop() ->
    gen_server:cast(?SERVER, stop).


%%--------------------------------------------------------------------
%% @spec register_aor(Aor) -> ok
%% @doc Start register server for the AOR if not already started,
%% @doc and send register request.
%% @end
%%--------------------------------------------------------------------
register_aor(Aor) when is_list(Aor) ->
    gen_server:call(?SERVER, {register, Aor}).


%%--------------------------------------------------------------------
%% @spec register_aor(Aor) -> ok
%% @doc Send unregister request
%% @end
%%--------------------------------------------------------------------
unregister_aor(Aor) when is_list(Aor) ->
    gen_server:call(?SERVER, {unregister, Aor}).


%%--------------------------------------------------------------------
%% gen_server callbacks
%%--------------------------------------------------------------------
init([]) ->
    process_flag(trap_exit, true),
    {ok, #state{}}.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_call({register, Aor}, _From, State) ->
    case register_sup:find_child(Aor) of
	{ok, undefined} ->
	    {ok, _Pid} = supervisor:restart_child(register_sup, Aor),
	    {reply, ok, State};
	{ok, Pid} ->
	    ok = sipregister:send_register(Pid),
	    {reply, ok, State};

	error ->
	    {ok, Request} = sipregister:build_register(Aor),
	    Pid =
		case register_sup:start_child(Aor, Request, self()) of
		    {ok, Pid1} ->
			Pid1;
		    {error, {already_started,  Child}} ->
			Child;
		    {error, already_present} ->
			{ok, Child} = supervisor:restart_child(register_sup, Aor),
			Child
	    end,

	    link(Pid),
	    {reply, ok, State}
    end;

handle_call({unregister, Aor}, _From, State) ->
    case register_sup:find_child(Aor) of
	{ok, undefined} ->
	    {reply, undefined, State};

	{ok, Pid} ->
	    Res = sipregister:send_unregister(Pid),
	    {reply, Res, State};

	error ->
	    {reply, error, State}
    end;

handle_call(Request, _From, State) ->
    error_logger:error_msg("Unhandled call in ~p: ~p~n", [?MODULE, Request]),
    {reply, ok, State}.


handle_cast(stop, State) ->
    {stop, normal, State};
handle_cast(Request, State) ->
    error_logger:error_msg("Unhandled cast in ~p: ~p~n", [?MODULE, Request]),
    {noreply, State}.

handle_info({unregistered, _Pid, Aor}, State) ->
    supervisor:delete_child(register_sup, Aor),
    {noreply, State};

%% handle_info({'EXIT', Pid, Reason}, State) ->
%%     case register_sup:find_child(Pid, State#state.pids) of
%% 	{ok, Aor} ->
%% 	    error_logger:info_msg("~p: Traped ~p ~p~n", [?MODULE, Pid, Reason]),
%% 	    supervisor:delete_child(register_sup, Aor),
%% 	    {noreply, State1};
%% 	error ->
%% 	    {stop, Reason, State}
%%     end;

handle_info(Info, State) ->
    error_logger:error_msg("Unhandled info in ~p: ~p~n", [?MODULE, Info]),
    {noreply, State}.


terminate(_Reason, _State) ->
    terminated.
