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

{
exception Bad_expander
type t =
  | Literal of string
  | Variable of (string * Lexing.position * Lexing.position)
  | Textend

let help id lb =
  Variable(id, Lexing.lexeme_start_p lb, Lexing.lexeme_end_p lb)
}

let upcase = [ 'A' - 'Z' ]
let downcase = [ 'a' - 'z' '_' ]
let number  = [ '0' - '9' ]
let id_suffix = upcase | downcase | number | '\''
let identifier = downcase id_suffix *

rule token = parse
  | '$' (identifier as id) {help id lexbuf}
  | '$' '{' (identifier as id) '}' {help id lexbuf}
  | '$' '$' {Literal("$")}
  | '$' {raise_notrace Bad_expander}
  | [^ '$' ]+  {Literal(Lexing.lexeme lexbuf)}
  | eof  { Textend }
  | _ {Literal(Lexing.lexeme lexbuf)}
