-module(tooterl).
-export([toot/3]).

toot(Status, AuthToken, Url)->

    Body=string:concat("status=", Status),
    
    Headers = [
	       {"Authorization", string:concat("Bearer ", AuthToken)}, 
	       {"Accept", "application/activity+json"},
	       {"User-Agent", "TootErl"},
	       {"Content-Length", integer_to_list(length(Body))},
	       {"Content-Type",  "application/x-www-form-urlencoded"}],
    Params=[{"status", Status}],


    io:format("~p~n", [Headers]),

    httpc:request(post,
		  {"https://mastodon.hccp.org/api/v1/statuses",
		   Headers,
		   "application/x-www-form-urlencoded",
		   Body
		  }, [], []).






%    MultiPartBody=generate_multipart__body(Params, "------boundary-----"),
%    {ok, Response} = httpc:request(post,
%				   {Url,
%				    Headers,
%				    "multipart/form-data",
%				    MultiPartBody
%				   }, [], [{headers_as_is, true},{body_format, binary}]).


toot(Status, Images, AuthToken, Url)->
    ok.

generate_multipart__body(Params, Boundary)->
    generate_multipart__body(Params, Boundary, []).

generate_multipart__body([H|T], Boundary, Acc)->
    {Name, Value}=H,
    Prefix = string:concat(Acc, string:concat(string:concat(string:concat(string:concat("--", Boundary), "\r\nContent-Disposition: form-data; name=\""), Name), "\"")),
    case Name of
	"media" ->
	    MediaAcc=string:concat(Prefix,"; filename=\"foo1.png\"\nContent-Type: application/octet-stream");
	_ ->
	    MediaAcc=Prefix
    end,
									       
    NewAcc = string:concat(string:concat(MediaAcc, string:concat("\r\n\r\n", Value)), "\r\n"),
    generate_multipart__body(T, Boundary, NewAcc);
generate_multipart__body([], Boundary, Acc) ->
    string:concat(Acc, string:concat(string:concat("--", Boundary), "--\r\n")).
