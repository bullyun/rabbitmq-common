%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at https://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is GoPivotal, Inc.
%% Copyright (c) 2007-2020 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(file_handle_cache_stats).

%% stats about read / write operations that go through the fhc.

-export([init/0, update/3, update/2, update/1, get/0]).

-define(TABLE, ?MODULE).

-define(COUNT,
        [io_reopen, mnesia_ram_tx, mnesia_disk_tx,
         msg_store_read, msg_store_write,
         queue_index_journal_write, queue_index_write, queue_index_read]).
-define(COUNT_TIME, [io_sync, io_seek, io_file_handle_open_attempt]).
-define(COUNT_TIME_BYTES, [io_read, io_write]).

init() ->
    _ = ets:new(?TABLE, [public, named_table]),
    [ets:insert(?TABLE, {{Op, Counter}, 0}) || Op      <- ?COUNT_TIME_BYTES,
                                               Counter <- [count, bytes, time]],
    [ets:insert(?TABLE, {{Op, Counter}, 0}) || Op      <- ?COUNT_TIME,
                                               Counter <- [count, time]],
    [ets:insert(?TABLE, {{Op, Counter}, 0}) || Op      <- ?COUNT,
                                               Counter <- [count]].

update(Op, Bytes, Thunk) ->
    {Time, Res} = timer_tc(Thunk),
    _ = ets:update_counter(?TABLE, {Op, count}, 1),
    _ = ets:update_counter(?TABLE, {Op, bytes}, Bytes),
    _ = ets:update_counter(?TABLE, {Op, time}, Time),
    Res.

update(Op, Thunk) ->
    {Time, Res} = timer_tc(Thunk),
    _ = ets:update_counter(?TABLE, {Op, count}, 1),
    _ = ets:update_counter(?TABLE, {Op, time}, Time),
    Res.

update(Op) ->
    ets:update_counter(?TABLE, {Op, count}, 1),
    ok.

get() ->
    lists:sort(ets:tab2list(?TABLE)).

timer_tc(Thunk) ->
    T1 = erlang:monotonic_time(),
    Res = Thunk(),
    T2 = erlang:monotonic_time(),
    Diff = erlang:convert_time_unit(T2 - T1, native, micro_seconds),
    {Diff, Res}.
