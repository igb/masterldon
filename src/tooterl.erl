-module(tooterl).
-export([toot/3, toot/4, get_secrets/0, get_statuses/3]).


get_headers(AuthToken, ContentLength, ContentType) ->
    [
     {"Authorization", string:concat("Bearer ", AuthToken)}, 
     {"Accept", "application/activity+json"},
     {"User-Agent", "TootErl"},
     {"Content-Length", integer_to_list(ContentLength)},
     {"Content-Type",  ContentType}].




get_secrets()->
        {ok,[[AuthToken]]}=init:get_argument(auth_token),
        {AuthToken}.





toot(Status, AuthToken, Url)->
    EncodedStatus=escape_uri(Status),
    
    Body=string:concat("status=", EncodedStatus),
    
    Headers = get_headers(AuthToken, length(Body), "application/x-www-form-urlencoded"),

    Params=[{"status", EncodedStatus}],


    io:format("~p~n", [Headers]),

    httpc:request(post,
		  {string:concat(Url, "/api/v1/statuses"),
		   Headers,
		   "application/x-www-form-urlencoded",
		   Body
		  }, [], []).


get_statuses(Id, AuthToken, Url)->
    Headers = get_headers(AuthToken, 0, "text/html; charset=utf-8"),
    {ok, {StatusLine, HttpHeader, HttpBodyResult}}=httpc:request(get,
		  {string:concat(string:concat(string:concat(Url, "/api/v1/accounts/"), Id), "/statuses"),
		   Headers }, [], []),
    jsone:decode(list_to_binary(HttpBodyResult), [{object_format, tuple}]).


toot(Status, Images, AuthToken, Url)->
    MediaIds=upload_images(Images, AuthToken, Url). 
    
upload_images(Images, AuthToken, Url)->
    upload_images(Images, AuthToken, Url, []).
    

upload_images([H|T], AuthToken, Url, Acc)->
    io:format("~p~n", [H]),
    MediaId=upload_image(H, AuthToken, Url),
    NewAcc=lists:append(Acc, [MediaId]),
    upload_images(T, AuthToken, Url, NewAcc);
upload_images([], AuthToken, Url, Acc)->
    Acc.

upload_image(Image, AuthToken, Url)->

    Boundary="===13978193024621189109088990673===",

%    io:format("~p~n", [Image]),
    {ok, Media} = file:read_file(Image),

    Params = [{"description", "an image"},{"file", base64:decode_to_string(base64:encode(Media))}],
    
    MultiPartBody=generate_multipart__body(Params, Boundary),

%    io:format("~s~n~n", [MultiPartBody]),
    file:write_file("/tmp/multi", io_lib:fwrite("~s", [MultiPartBody])),
    Headers = get_headers(AuthToken, length(MultiPartBody), string:concat("multipart/form-data; boundary=", Boundary)),
    io:format("~p~n", [Headers]),


    {ok, Response} = httpc:request(post,
				   {string:concat(Url, "/api/v1/media"),
				    Headers,
				    "multipart/form-data",
				    MultiPartBody
				   }, [], [{body_format, binary}]).



% {body_format, binary}
generate_multipart__body(Params, Boundary)->
    generate_multipart__body(Params, Boundary, []).

generate_multipart__body([H|T], Boundary, Acc)->
    {Name, Value}=H,
    Prefix = string:concat(Acc, string:concat(string:concat(string:concat(string:concat("--", Boundary), "\r\nContent-Disposition: form-data; name=\""), Name), "\"")),
    case Name of
	"file" ->
	    MediaAcc=string:concat(Prefix,"; filename=\"foo1.png\"\nContent-Type: image/png");
	_ ->
	    MediaAcc=Prefix
    end,
									       
    NewAcc = string:concat(string:concat(MediaAcc, string:concat("\r\n\r\n", Value)), "\r\n"),
    generate_multipart__body(T, Boundary, NewAcc);
generate_multipart__body([], Boundary, Acc) ->
    string:concat(Acc, string:concat(string:concat("--", Boundary), "--\r\n")).


escape_uri([C | Cs]) when C >= $a, C =< $z ->
    [C | escape_uri(Cs)];
escape_uri([C | Cs]) when C >= $A, C =< $Z ->
    [C | escape_uri(Cs)];
escape_uri([C | Cs]) when C >= $0, C =< $9 ->
    [C | escape_uri(Cs)];
escape_uri([C = $. | Cs]) ->
    [C | escape_uri(Cs)];
escape_uri([C = $- | Cs]) ->
    [C | escape_uri(Cs)];
escape_uri([C = $_ | Cs]) ->
    [C | escape_uri(Cs)];
escape_uri([C | Cs]) when C > 16#7f ->
    HexStr = integer_to_list(C, 16),
    lists:flatten([$%, HexStr]) ++ escape_uri(Cs);
escape_uri([C | Cs]) ->
    escape_byte(C) ++ escape_uri(Cs);
escape_uri([]) ->
    [].

escape_byte(C) when C >= 0, C =< 255 ->
    [$%, hex_digit(C bsr 4), hex_digit(C band 15)].

hex_digit(N) when N >= 0, N =< 9 ->
    N + $0;
hex_digit(N) when N > 9, N =< 15 ->
    N + $A - 10.

