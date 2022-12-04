-module(tooterl).
-export([toot/3]).


get_headers(AuthToken, ContentLength, ContentType) ->
    [
     {"Authorization", string:concat("Bearer ", AuthToken)}, 
     {"Accept", "application/activity+json"},
     {"User-Agent", "TootErl"},
     {"Content-Length", integer_to_list(ContentLength)},
     {"Content-Type",  ContentType}].


toot(Status, AuthToken, Url)->

    Body=string:concat("status=", Status),
    
    Headers = get_headers(AuthToken, length(Body), "application/x-www-form-urlencoded"),

    Params=[{"status", Status}],


    io:format("~p~n", [Headers]),

    httpc:request(post,
		  {string:concat(Url, "/api/v1/statuses"),
		   Headers,
		   "application/x-www-form-urlencoded",
		   Body
		  }, [], []).


toot(Status, Images, AuthToken, Url)->
    MediaIds=upload_images(Images, AuthToken, Url). 
    
upload_images(Images, AuthToken, Url)->
    upload_images(Images, AuthToken, Url, []).
    

upload_images([H|T], AuthToken, Url, Acc)->
    MediaId=upload_image(H, AuthToken, Url),
    NewAcc=lists:append(Acc, [MediaId]),
    upload_images(T, AuthToken, Url, NewAcc);
upload_images([], AuthToken, Url, Acc)->
    Acc.

upload_image(Image, AuthToken, Url)->

    
    {ok, Media} = file:read_file(Image),

    Params = [{"file", base64:decode_to_string(Media)}],
    
    MultiPartBody=generate_multipart__body(Params, "------boundary-----"),

    Headers = get_headers(AuthToken, length(MultiPartBody), "multipart/form-data"),
    {ok, Response} = httpc:request(post,
				   {Url,
				    Headers,
				    "multipart/form-data",
				    MultiPartBody
				   }, [], [{headers_as_is, true},{body_format, binary}]).




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
