%% This file contains an implementation of a simple key-value store.
%% The key-value store is managed by a server, and implemented as a binary tree.

-module(kv).

-include_lib("eqc/include/eqc.hrl").

-compile({parse_transform,eqc_cover}).
-compile(export_all).

%% -- API functions ----------------------------------------------------------

start() ->
  catch unregister(kv),
  register(kv, spawn_link(fun() -> server(leaf) end)).

insert(K, V) ->
  kv ! {insert, K, V},
  ok.

lookup(K) ->
  kv ! {lookup, K, self()},
  receive Msg -> Msg end.

%% delete(K) ->
%%   kv ! {delete, K},
%%   ok.

%% -- Internal functions -----------------------------------------------------

server(T) ->
  receive
    {insert, K, V} ->
      server(insert(K, V, T));
    %% {delete, K} ->
    %%   server(delete(K, T));
    {lookup, K, Pid} ->
      Pid ! lookup(K, T),
      server(T)
  after 5000 ->
      %% Our server dies after 5 seconds of inactivity... just so we
      %% don't fill the memory with idle servers.
      ok
  end.

insert(K, V, leaf) ->
  {node, leaf, K, V, leaf};
insert(K, V, {node, L, KN, _VN, R}) ->
  if K < KN ->
      insert(K, V, L);
     K == KN ->
      {node, L, K, V, R};
     K > KN ->
      insert(K, V, R)
  end.

lookup(_, leaf) ->
  false;
lookup(K, {node, L, KN, VN, R}) ->
  if K < KN ->
      lookup(K, R);
     K == KN ->
      {K, VN};
     K > KN ->
      lookup(K, L)
  end.

%% delete(_K, leaf) ->
%%   leaf;
%% delete(K, {node, L, KN, VN, R}) ->
%%   if K<KN ->
%%       {node, delete(K, L), KN, VN, R};
%%      K==KN ->
%%       merge(L, R);
%%      K>KN ->
%%       {node, L, KN, VN, delete(K, R)}
%%   end.

%% merge(leaf, R) ->
%%   R;
%% merge(L, leaf) ->
%%   L;
%% merge({node, LL, LK, LV, LR}, {node, RL, RK, RV, RR}) ->
%%   {node, LL, LK, LV, {node, merge(RL, LR), RK, RV, RR}}.
