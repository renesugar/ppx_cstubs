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

let h s =
  let x = Location.mkloc s Location.none in
  (x, Mparsetree.Ast_cur.Parsetree.PStr [])

let replace_expr_string = "ppxc__replace_expr"

let replace_expr_attrib = h replace_expr_string

let tdl_string = "ppxc__tdl"

let tdl_attrib = h tdl_string

let remove_string = "ppxc__remove"

let remove_attrib = h remove_string

let replace_attr_string = "ppxc__replace_attr"

let replace_typ_string = "ppxc__replace_typ"

let replace_struct_string = "ppxc__replace_struct"
