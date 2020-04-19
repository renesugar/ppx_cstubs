(* This file is part of ppx_cstubs (https://github.com/fdopen/ppx_cstubs)
 * Copyright (c) 2018-2019 fdopen
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

let executable = Filename.basename Sys.executable_name

let error_exit s =
  Printf.eprintf "%s: %s Try %s --help\n" executable s executable;
  exit 1

let common_main argv =
  set_binary_mode_out stdout true;
  set_binary_mode_out stderr true;
  set_binary_mode_in stdin true;
  Ppx_main.init ();
  Migrate_parsetree.Driver.run_main ~argv ()

let cpp_main () =
  let usage =
    Printf.sprintf "%s [<file>] -o-ml my_module.ml -o-c my_module_stubs.c"
      executable
  in
  let anon_is_target = ref false in
  let na f p =
    anon_is_target := false;
    f p
  in
  let arg_set_string v = Arg.String (na (fun s -> v := s)) in
  let arg_set v = Arg.Unit (na (fun () -> v := true)) in
  let arg_string f = Arg.String (na f) in
  let arg_set_int v = Arg.Int (na (fun a -> v := a)) in
  let ml_output = ref "" in
  let c_output = ref "" in
  let pretty = ref false in
  let cflags = ref [] in
  let cflags_rest = ref [] in
  let oflags = ref (List.rev Options.ocaml_flags_default) in
  let include_dirs = ref [] in
  let keep_tmp = ref false in
  let toolchain = ref None in
  let cc = ref None in
  let findlib_pkgs = ref [] in
  let cma_files = ref [] in
  let verbose = ref 1 in
  let absname = ref false in
  let nopervasives = ref false in
  let no_openstruct = ref false in
  let set_output_by_suffix s =
    match CCString.Split.right ~by:"." s with
    | None ->
      if CCString.lowercase_ascii s = "none" then c_output := s
      else raise (Arg.Bad s)
    | Some (_, suf) -> (
      if String.length suf = 0 then raise (Arg.Bad s);
      match CCChar.lowercase_ascii suf.[0] with
      | 'r' | 'm' -> ml_output := s
      | 'c' -> c_output := s
      | _ -> raise (Arg.Bad s) )
  in
  let spec =
    Arg.align
      [
        ( "-o-ml",
          arg_set_string ml_output,
          "<file>    write generated OCaml file to <file>" );
        ( "-o-c",
          arg_set_string c_output,
          "<file>    write generated C file to <file>" );
        ( "-o",
          Arg.String
            (fun s ->
              anon_is_target := true;
              set_output_by_suffix s),
          "<file1>\xC2\xA0<file2>    \xC2\xA0write generated files to <file1> and <file2>. The files must have proper suffixes"
        );
        ( "-cflag",
          arg_string (fun s -> cflags := s :: !cflags),
          "<opt>     Pass option <opt> to the C compiler" );
        ( "-I",
          arg_string (fun s ->
              include_dirs := s :: !include_dirs;
              oflags := s :: "-I" :: !oflags;
              anon_is_target := false),
          "<dir>     Add <dir> to the list of include directories" );
        ( "-pkg",
          arg_string (fun s -> findlib_pkgs := s :: !findlib_pkgs),
          "<opt>     import types from findlib package <opt>" );
        ( "-toolchain",
          arg_string (fun s -> toolchain := Some s),
          "<opt>     use ocamlfind toolchain <opt>" );
        ("-keep-tmp", arg_set keep_tmp, "     Don't delete temporary files");
        ( "-pretty",
          arg_set pretty,
          "     Print a human readable ml file instead of the binary ast" );
        ( "-verbose",
          arg_set_int verbose,
          "<level>   Set the level of verbosity. By default, it is set to 1" );
        ( "-quiet",
          Arg.Unit (na (fun () -> verbose := 0)),
          "         Make ppx_cstubs silent. Same as -verbose 0" );
        ( "-absname",
          arg_set absname,
          "     Show absolute filenames in error messages" );
        ( "-no-openstruct",
          arg_set no_openstruct,
          "    Disable hiding through 'open struct'." );
        ("-nopervasives", arg_set nopervasives, "     (undocumented)");
        ( "-cc",
          arg_string (fun s -> cc := Some s),
          "<command>      Use <command> as the C compiler" );
        ( "--",
          Arg.Rest (fun a -> cflags_rest := a :: !cflags_rest),
          "     Pass all following parameters verbatim to the c compiler" );
      ]
  in
  let add_cma_file a =
    if Sys.file_exists a then cma_files := a :: !cma_files
    else
      let c =
        ListLabels.exists !include_dirs ~f:(fun d ->
            let a = Filename.concat d a in
            if Sys.file_exists a then (
              cma_files := a :: !cma_files;
              true )
            else false)
      in
      if c = false then Printf.sprintf "%S doesn't exist\n" a |> error_exit
  in
  let source = ref None in
  Arg.parse spec
    (fun a ->
      if a = "" then raise (Arg.Bad a);
      let la = CCString.lowercase_ascii a in
      if Filename.check_suffix la ".cma" || Filename.check_suffix la ".cmo" then (
        anon_is_target := false;
        add_cma_file a )
      else if !anon_is_target then (
        anon_is_target := false;
        set_output_by_suffix a )
      else (
        if !source <> None then raise (Arg.Bad a);
        source := Some a ))
    usage;
  let source =
    match !source with
    | None -> error_exit "no source file specified"
    | Some s -> s
  in
  let ml_output =
    match !ml_output with "" -> error_exit "ml output file missing" | c -> c
  in
  let c_output = match !c_output with "" -> "none" | s -> s in
  if ml_output = c_output then error_exit "use different output files";
  if !absname then Toplevel.set_absname true;
  let h s =
    let s = CCString.lowercase_ascii s in
    let s = Filename.basename s in
    try Filename.chop_extension s with Invalid_argument _ -> s
  in
  if CCString.lowercase_ascii c_output <> "none" then (
    if h ml_output = h c_output then
      error_exit "filenames must differ, not only their suffix";
    Options.c_output_file := Some c_output );
  Options.ocaml_flags := List.rev !oflags;
  Options.c_flags := List.rev !cflags @ List.rev !cflags_rest;
  Options.keep_tmp := !keep_tmp;
  Options.nopervasives := !nopervasives;
  Options.mode := Options.Regular;
  Options.ml_input_file := Some source;
  Options.ml_output_file := Some ml_output;
  Options.toolchain := !toolchain;
  Options.cma_files := List.rev !cma_files;
  Options.findlib_pkgs := List.rev !findlib_pkgs;
  Options.use_open_struct := not !no_openstruct;
  Options.verbosity := !verbose;
  Options.cc := !cc;
  Options.pretty := !pretty;
  (* trigger exceptions *)
  Ocaml_config.init ();
  if !findlib_pkgs <> [] || !cma_files <> [] then Toplevel.init ();
  let l = if ml_output = "-" then [] else [ "-o"; ml_output ] in
  let l = source :: l in
  let l = if !pretty then l else "--dump-ast" :: l in
  let l = Sys.argv.(0) :: l in
  common_main (Array.of_list l)

let merlin_main () =
  Options.mode := Options.Emulate;
  common_main Sys.argv

let init () =
  if CCArray.exists (( = ) "--as-ppx") Sys.argv then merlin_main ()
  else cpp_main ()
