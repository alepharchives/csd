-module(csd_web_vote_submit_resource).
-author('OJ Reeves <oj@buffered.io>').

%% --------------------------------------------------------------------------------------
%% API Function Exports
%% --------------------------------------------------------------------------------------

-export([
    init/1,
    allowed_methods/2,
    is_authorized/2,
    process_post/2
  ]).

%% --------------------------------------------------------------------------------------
%% Internal Record Definitions
%% --------------------------------------------------------------------------------------

-record(state, {
    user_data = undefined
  }).

%% --------------------------------------------------------------------------------------
%% Required Includes
%% --------------------------------------------------------------------------------------

-include_lib("webmachine/include/webmachine.hrl").

%% --------------------------------------------------------------------------------------
%% API Function Definitions
%% --------------------------------------------------------------------------------------

init([]) ->
  {ok, #state{}}.

allowed_methods(ReqData, State=#state{}) ->
  {['POST'], ReqData, State}.

is_authorized(ReqData, State=#state{}) ->
  case cookie:load_auth(ReqData) of
    {ok, UserData} ->
      {true, ReqData, State#state{user_data=UserData}};
    _ ->
      {false, ReqData, State}
  end.

process_post(ReqData, State=#state{user_data={UserId, _, _, _}}) ->
  FormData = mochiweb_util:parse_qs(wrq:req_body(ReqData)),
  SnippetId = proplists:get_value("snippet", FormData),
  Which = proplists:get_value("which", FormData),
  Vote = csd_vote:to_vote(UserId, SnippetId, Which),
  {ok, _} = csd_vote:save(Vote),
  {ok, Count} = csd_vote:count_for_snippet(SnippetId, UserId),
  Json = csd_vote:to_json(Count),
  NewReqData = wrq:set_resp_header("Content-type", "application/json", wrq:set_resp_body(Json, ReqData)),
  {true, NewReqData, State}.

