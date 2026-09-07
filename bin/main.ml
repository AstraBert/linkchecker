let usage_msg = "linkchecker [-verbose] [-base <url>] <file>"

let verbose = ref false
let file_name = ref ""
let base = ref "http://localhost:1313"

let anon_fun file = file_name := file

let speclist =
  [
    ("-verbose", Arg.Set verbose, "Output debug information");
    ("-base", Arg.Set_string base, "Base URL for relative links (starting with `/`, such as `/documentation/doc`).\n\tDefaults to http://localhost:1313.");
  ]
let () = Arg.parse speclist anon_fun usage_msg
let () = match !file_name with
  | "" -> raise (Failure "No file_name provided")
  | _ -> ()

(* read the entire file *)
let read_file file =
 In_channel.with_open_bin file In_channel.input_all

let regex = Re.Pcre.re "\\[.*?\\]\\((.*?)\\)" |> Re.compile
let find_all_matches content = Re.all regex content
let extract_url re_match = Re.Group.get re_match 1
let content = read_file !file_name
let all_matches = find_all_matches content
let urls = List.map extract_url all_matches
let () = print_string (if !verbose && List.length urls > 0 then "Checking the following URLs:\n" else "")
let () = print_string (if !verbose && List.length urls == 0 then "No URLs to check\n" else "")
let () =
  let f elem = print_string (if !verbose then elem ^ "\n" else "") in
  List.iter f urls

let normalize_url url = if String.starts_with ~prefix:"/" url then !base ^ url else url

open Lwt.Infix

let rec check_url ?(max_redirects = 5) uri =
  if (String.starts_with ~prefix:"#" uri) then Lwt.return (Ok ())
  else if max_redirects = 0 then Lwt.return (Error "too many redirects")
  else
    Lwt.catch
      (fun () ->
        Cohttp_lwt_unix.Client.get (Uri.of_string uri) >>= fun (resp, _body) ->
        let status = Cohttp.Response.status resp in
        match Cohttp.Code.code_of_status status with
        | code when code >= 200 && code < 300 -> Lwt.return (Ok ())
        | code when code >= 300 && code < 400 -> (
            match Cohttp.Header.get (Cohttp.Response.headers resp) "location" with
            | Some loc -> check_url ~max_redirects:(max_redirects - 1) loc
            | None -> Lwt.return (Error (Printf.sprintf "redirect with no location for %s" uri)))
        | code -> Lwt.return (Error (Printf.sprintf "Broken link %s: HTTP %d" uri code)))
      (fun exn ->
        Lwt.return (Error (Printf.sprintf "Request failed for %s: %s" uri (Printexc.to_string exn))))

let check_failure res = match res with
  | Error e -> print_endline e
  | Ok () -> ()


let norm_urls = List.map normalize_url urls
let () =
  Lwt_main.run (Lwt_list.iter_p (fun elem -> check_url elem >|= check_failure) norm_urls)
